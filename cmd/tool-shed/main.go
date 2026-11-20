package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
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
	command, passthrough, err := parseArgs(args)
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

func parseArgs(args []string) (string, []string, error) {
	if len(args) == 0 {
		return "", nil, usageError("missing command")
	}

	command := args[0]
	if command == "-h" || command == "--help" || command == "help" {
		return "", nil, usageError("")
	}

	if _, ok := commandScripts[command]; !ok {
		return "", nil, usageError(fmt.Sprintf("unknown command: %s", command))
	}

	return command, args[1:], nil
}

func usageError(detail string) error {
	if detail != "" {
		fmt.Fprintln(os.Stderr, detail)
	}
	fmt.Fprintln(os.Stderr, "Usage: tool-shed [install|update|uninstall|list] [args...]")
	return errors.New("invalid arguments")
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
