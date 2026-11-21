package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/derekpedersen/tool-shed/.cmd/internal/manifest"
	"github.com/derekpedersen/tool-shed/.cmd/internal/resolver"
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
			// Phase 2 keeps shell backends for non-install commands.
		}
	}

	return runShellCommand(repoRoot, parsed.command, parsed.passthrough)
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
	command     string
	passthrough []string
}

func parseArgs(args []string) (parsedArgs, error) {
	runtime := os.Getenv("TOOL_SHED_RUNTIME")
	if runtime == "" {
		runtime = "shell"
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
		default:
			goto parseCommand
		}
	}

parseCommand:
	if runtime != "shell" && runtime != "go" {
		return parsedArgs{}, usageError(fmt.Sprintf("invalid runtime: %s", runtime))
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

	return parsedArgs{runtime: runtime, command: command, passthrough: args[i+1:]}, nil
}

func usageError(detail string) error {
	if detail != "" {
		fmt.Fprintln(os.Stderr, detail)
	}
	fmt.Fprintln(os.Stderr, "Usage: tool-shed [--runtime shell|go] [install|update|uninstall|list] [args...]")
	return errors.New("invalid arguments")
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
