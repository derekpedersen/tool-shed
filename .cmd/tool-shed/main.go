package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/derekpedersen/tool-shed/.cmd/internal/catalog"
	"github.com/derekpedersen/tool-shed/.cmd/internal/manifest"
	"github.com/derekpedersen/tool-shed/.cmd/internal/nativebackend"
	"github.com/derekpedersen/tool-shed/.cmd/internal/resolver"
	"github.com/derekpedersen/tool-shed/.cmd/internal/state"
)

var commandScripts = map[string]string{
	"install":   "install.sh",
	"update":    "update.sh",
	"uninstall": "uninstall.sh",
	"list":      "list.sh",
}

func main() {
	if err := run(os.Args[1:]); err != nil {
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			os.Exit(exitErr.ExitCode())
		}
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func runShellCommand(repoRoot string, command string, passthrough []string) error {

	scriptPath := filepath.Join(repoRoot, commandScripts[command])
	if _, err := os.Stat(scriptPath); err != nil {
		if errors.Is(err, os.ErrNotExist) {
			return fmt.Errorf("required script is missing: %s", scriptPath)
		}
		return fmt.Errorf("verify script path %s: %w", scriptPath, err)
	}

	cmd := exec.Command("bash", append([]string{scriptPath}, passthrough...)...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = os.Environ()

	return cmd.Run()
}

type parsedArgs struct {
	runtime     string
	backend     string
	command     string
	passthrough []string
}

type nativeOptions struct {
	dryRun          bool
	targets         []string
	allowMajor      bool
	includeServices bool
	yes             bool
	withPackages    bool
	adopt           bool
	list            bool
}

func parseArgs(args []string) (parsedArgs, error) {
	runtime := os.Getenv("TOOL_SHED_RUNTIME")
	if runtime == "" {
		runtime = "shell"
	}
	backend := os.Getenv("TOOL_SHED_BACKEND")
	if backend == "" {
		backend = "shell"
	}

	if len(args) == 0 {
		return parsedArgs{}, usageError("missing command")
	}

	i := 0
	for i < len(args) {
		arg := args[i]
		switch {
		case arg == "--runtime":
			i++
			if i >= len(args) {
				return parsedArgs{}, usageError("--runtime requires a value")
			}
			runtime = args[i]
			i++
		case strings.HasPrefix(arg, "--runtime="):
			runtime = strings.TrimPrefix(arg, "--runtime=")
			i++
		case arg == "--backend":
			i++
			if i >= len(args) {
				return parsedArgs{}, usageError("--backend requires a value")
			}
			backend = args[i]
			i++
		case strings.HasPrefix(arg, "--backend="):
			backend = strings.TrimPrefix(arg, "--backend=")
			i++
		default:
			goto parseCommand
		}
	}

parseCommand:
	if runtime != "shell" && runtime != "go" {
		return parsedArgs{}, usageError(fmt.Sprintf("invalid runtime: %s", runtime))
	}
	if backend != "shell" && backend != "native" {
		return parsedArgs{}, usageError(fmt.Sprintf("invalid backend: %s", backend))
	}
	if i >= len(args) {
		return parsedArgs{}, usageError("missing command")
	}

	command := args[i]
	if command == "-h" || command == "--help" || command == "help" {
		return parsedArgs{}, usageError("")
	}

	if _, ok := commandScripts[command]; !ok {
		return parsedArgs{}, usageError(fmt.Sprintf("unknown command: %s", command))
	}

	return parsedArgs{runtime: runtime, backend: backend, command: command, passthrough: args[i+1:]}, nil
}

func usageError(detail string) error {
	if detail != "" {
		fmt.Fprintln(os.Stderr, detail)
	}
	fmt.Fprintln(os.Stderr, "Usage: tool-shed [--runtime shell|go] [--backend shell|native] [install|update|uninstall|list] [args...]")
	return errors.New("invalid arguments")
}

func run(args []string) error {
	parsed, err := parseArgs(args)
	if err != nil {
		return err
	}

	cwd, err := os.Getwd()
	if err != nil {
		return fmt.Errorf("determine working directory: %w", err)
	}

	repoRoot, err := findRepoRoot(cwd)
	if err != nil {
		return err
	}

	if parsed.runtime == "go" {
		if parsed.backend == "native" {
			if err := runNativeBackend(repoRoot, parsed.command, parsed.passthrough); err != nil {
				if errors.Is(err, nativebackend.ErrNoSupportedTools) {
					fmt.Fprintln(os.Stdout, "Falling back to shell backend for compatibility.")
					return runShellCommand(repoRoot, parsed.command, parsed.passthrough)
				}
				return err
			}
			return nil
		}

		switch parsed.command {
		case "install":
			return runInstallGoRuntime(repoRoot, parsed.passthrough)
		case "update":
			return runUpdateGoRuntime(repoRoot, parsed.passthrough)
		case "uninstall":
			return runUninstallGoRuntime(repoRoot, parsed.passthrough)
		case "list":
			return runListGoRuntime(repoRoot, parsed.passthrough)
		default:
			// Go runtime only supports known command names.
		}
	}

	return runShellCommand(repoRoot, parsed.command, parsed.passthrough)
}

func runNativeBackend(repoRoot string, command string, args []string) error {
	c, err := catalog.Load(repoRoot)
	if err != nil {
		return err
	}
	m, err := manifest.Load(repoRoot)
	if err != nil {
		return err
	}
	b := nativebackend.New(c)

	opts := parseNativeOptions(args)
	stateDir := getStateDir()

	switch command {
	case "install":
		if len(opts.targets) == 0 {
			opts.targets = []string{"full"}
			fmt.Fprintln(os.Stdout, "No install target provided. Defaulting to: full")
		}
		resolved := resolver.Resolve(m, opts.targets)
		if !allNativeSupported(b, resolved) {
			return nativebackend.ErrNoSupportedTools
		}
		return b.Install(resolved, opts.dryRun)
	case "uninstall":
		if len(opts.targets) == 0 {
			return errors.New("an explicit uninstall target is required; refusing to default to the full bundle")
		}
		resolved := resolver.Resolve(m, opts.targets)
		if !allNativeSupported(b, resolved) {
			return nativebackend.ErrNoSupportedTools
		}
		return b.Uninstall(resolved, opts.dryRun)
	case "update":
		if opts.adopt || opts.list || opts.withPackages {
			return nativebackend.ErrNoSupportedTools
		}
		if len(opts.targets) == 0 {
			names, err := state.ListToolRecordNames(stateDir)
			if err != nil {
				return err
			}
			opts.targets = names
		}
		resolved := resolver.Resolve(m, opts.targets)
		if len(resolved) == 0 {
			fmt.Fprintln(os.Stdout, "No managed tools recorded. Use --adopt TOOL or --adopt BUNDLE for existing installations.")
			return nil
		}
		eligible, err := filterNativeUpdateTargets(stateDir, resolved, opts)
		if err != nil {
			return err
		}
		if len(eligible) == 0 {
			fmt.Fprintln(os.Stdout, "No eligible managed tools for native update after policy checks.")
			return nil
		}
		if !allNativeSupported(b, eligible) {
			return nativebackend.ErrNoSupportedTools
		}
		return b.Update(eligible, opts.dryRun)
	case "list":
		var resolved []string
		if len(opts.targets) == 0 {
			names, err := state.ListToolRecordNames(stateDir)
			if err != nil {
				return err
			}
			if len(names) == 0 {
				fmt.Fprintln(os.Stdout, "No managed tools recorded. Use --adopt TOOL or --adopt BUNDLE for existing installations.")
				return nil
			}
			resolved = names
		} else {
			resolved = resolver.Resolve(m, opts.targets)
		}
		if len(resolved) == 0 {
			fmt.Fprintln(os.Stdout, "No valid list targets were resolved.")
			return nil
		}
		if !allNativeSupported(b, resolved) {
			return nativebackend.ErrNoSupportedTools
		}
		return b.List(resolved)
	default:
		return fmt.Errorf("unsupported command for native backend: %s", command)
	}
}

func parseNativeOptions(args []string) nativeOptions {
	opts := nativeOptions{targets: make([]string, 0, len(args))}
	for _, arg := range args {
		switch arg {
		case "--dry-run", "-n":
			opts.dryRun = true
		case "--allow-major":
			opts.allowMajor = true
		case "--include-services":
			opts.includeServices = true
		case "--yes":
			opts.yes = true
		case "--with-packages":
			opts.withPackages = true
		case "--adopt":
			opts.adopt = true
		case "--list":
			opts.list = true
		default:
			if strings.HasPrefix(arg, "-") {
				continue
			}
			opts.targets = append(opts.targets, arg)
		}
	}
	return opts
}

func getStateDir() string {
	stateDir := os.Getenv("TOOL_SHED_STATE_DIR")
	if stateDir != "" {
		return stateDir
	}
	return filepath.Join(os.Getenv("HOME"), ".tool-shed", "state")
}

func filterNativeUpdateTargets(stateDir string, resolved []string, opts nativeOptions) ([]string, error) {
	eligible := make([]string, 0, len(resolved))
	for _, tool := range resolved {
		recordPath := filepath.Join(stateDir, "tools", tool)
		record, err := state.ReadToolRecord(recordPath)
		if err != nil {
			if errors.Is(err, os.ErrNotExist) {
				fmt.Fprintf(os.Stdout, "SKIPPED %s is not managed. Use .tools/update.sh --adopt %s first.\n", tool, tool)
				continue
			}
			return nil, err
		}
		_ = record

		pinPath := filepath.Join(stateDir, "pins", tool)
		if _, err := os.Stat(pinPath); err == nil {
			fmt.Fprintf(os.Stdout, "SKIPPED %s is pinned in the tool-shed state directory.\n", tool)
			continue
		} else if err != nil && !errors.Is(err, os.ErrNotExist) {
			return nil, err
		}

		if isServiceTool(tool) && (!opts.includeServices || !opts.yes) {
			fmt.Fprintf(os.Stdout, "SKIPPED %s requires --include-services --yes after taking a backup; updates may restart services.\n", tool)
			continue
		}
		if tool == "julia" && !opts.allowMajor {
			fmt.Fprintln(os.Stdout, "SKIPPED Julia updates require --allow-major after reviewing the selected Juliaup channels.")
			continue
		}

		eligible = append(eligible, tool)
	}
	return eligible, nil
}

func isServiceTool(tool string) bool {
	switch tool {
	case "postgres", "redis", "mysql", "mongodb", "rabbitmq", "elasticsearch", "kafka", "docker":
		return true
	default:
		return false
	}
}

func allNativeSupported(b *nativebackend.Backend, tools []string) bool {
	for _, tool := range tools {
		if !b.Supports(tool) {
			return false
		}
	}
	return true
}

func runInstallGoRuntime(repoRoot string, args []string) error {
	dryRun, targets := parseDryRunTargets(args)

	if len(targets) == 0 {
		targets = []string{"full"}
		fmt.Fprintln(os.Stdout, "No install target provided. Defaulting to: full")
	}

	m, err := manifest.Load(repoRoot)
	if err != nil {
		return err
	}
	resolved := resolver.Resolve(m, targets)
	if len(resolved) == 0 {
		return errors.New("no valid installer targets were resolved")
	}

	if dryRun {
		fmt.Fprintln(os.Stdout, "DRY RUN: would install the following packages/tools:")
		for _, target := range resolved {
			fmt.Fprintf(os.Stdout, "  - %s\n", target)
		}
		fmt.Fprintf(os.Stdout, "Dry run complete for: %s\n", strings.Join(resolved, " "))
		return nil
	}

	return runShellCommand(repoRoot, "install", args)
}

func runUpdateGoRuntime(repoRoot string, args []string) error {
	dryRun, targets := parseDryRunTargets(args)
	if !dryRun {
		return runShellCommand(repoRoot, "update", args)
	}

	m, err := manifest.Load(repoRoot)
	if err != nil {
		return err
	}

	if len(targets) == 0 {
		fmt.Fprintln(os.Stdout, "DRY RUN: would update all managed, installed tools from state.")
		return nil
	}

	resolved := resolver.Resolve(m, targets)
	if len(resolved) == 0 {
		return errors.New("no valid update targets were resolved")
	}

	fmt.Fprintln(os.Stdout, "DRY RUN: would update the following tools:")
	for _, target := range resolved {
		fmt.Fprintf(os.Stdout, "  - %s\n", target)
	}
	return nil
}

func runUninstallGoRuntime(repoRoot string, args []string) error {
	dryRun, targets := parseDryRunTargets(args)
	if !dryRun {
		return runShellCommand(repoRoot, "uninstall", args)
	}

	if len(targets) == 0 {
		return errors.New("an explicit uninstall target is required; refusing to default to the full bundle")
	}

	m, err := manifest.Load(repoRoot)
	if err != nil {
		return err
	}
	resolved := resolver.Resolve(m, targets)
	if len(resolved) == 0 {
		return errors.New("no valid uninstall targets were resolved")
	}

	fmt.Fprintln(os.Stdout, "DRY RUN: would uninstall the following tools:")
	for _, target := range resolved {
		fmt.Fprintf(os.Stdout, "  - %s\n", target)
	}
	return nil
}

func runListGoRuntime(repoRoot string, args []string) error {
	_, targets := parseDryRunTargets(args)
	if len(targets) == 0 {
		return runShellCommand(repoRoot, "list", args)
	}

	m, err := manifest.Load(repoRoot)
	if err != nil {
		return err
	}
	resolved := resolver.Resolve(m, targets)
	if len(resolved) == 0 {
		fmt.Fprintln(os.Stdout, "No valid list targets were resolved.")
		return nil
	}

	fmt.Fprintln(os.Stdout, "Resolved list targets:")
	for _, target := range resolved {
		fmt.Fprintf(os.Stdout, "  - %s\n", target)
	}
	return nil
}

func parseDryRunTargets(args []string) (bool, []string) {
	dryRun := false
	targets := make([]string, 0, len(args))
	for _, arg := range args {
		switch arg {
		case "--dry-run", "-n":
			dryRun = true
		default:
			if strings.HasPrefix(arg, "-") {
				continue
			}
			targets = append(targets, arg)
		}
	}
	return dryRun, targets
}

func findRepoRoot(start string) (string, error) {
	current := start
	for {
		if hasRootScripts(current) {
			return current, nil
		}

		parent := filepath.Dir(current)
		if parent == current {
			return "", errors.New("could not locate repository root with install.sh/update.sh/uninstall.sh/list.sh")
		}
		current = parent
	}
}

func hasRootScripts(dir string) bool {
	required := []string{"install.sh", "update.sh", "uninstall.sh", "list.sh"}
	for _, script := range required {
		if _, err := os.Stat(filepath.Join(dir, script)); err != nil {
			return false
		}
	}
	return true
}
