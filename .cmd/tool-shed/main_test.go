package main

import (
	"bytes"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
)

var ioCaptureMu sync.Mutex

func captureStdout(t *testing.T, fn func() error) (string, error) {
	t.Helper()
	ioCaptureMu.Lock()
	defer ioCaptureMu.Unlock()

	originalStdout := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("create pipe: %v", err)
	}
	os.Stdout = w

	runErr := fn()

	_ = w.Close()
	os.Stdout = originalStdout

	var output bytes.Buffer
	if _, err := output.ReadFrom(r); err != nil {
		t.Fatalf("read captured output: %v", err)
	}
	return output.String(), runErr
}

func TestParseArgs(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name        string
		args        []string
		wantRuntime string
		wantCommand string
		wantArgs    []string
		wantErr     bool
	}{
		{
			name:        "install with passthrough",
			args:        []string{"install", "cloud", "--dry-run"},
			wantRuntime: "shell",
			wantCommand: "install",
			wantArgs:    []string{"cloud", "--dry-run"},
			wantErr:     false,
		},
		{
			name:        "list with no extra args",
			args:        []string{"list"},
			wantRuntime: "shell",
			wantCommand: "list",
			wantArgs:    []string{},
			wantErr:     false,
		},
		{
			name:        "runtime flag inline",
			args:        []string{"--runtime=go", "install", "full", "--dry-run"},
			wantRuntime: "go",
			wantCommand: "install",
			wantArgs:    []string{"full", "--dry-run"},
			wantErr:     false,
		},
		{
			name:        "runtime flag separate",
			args:        []string{"--runtime", "go", "list"},
			wantRuntime: "go",
			wantCommand: "list",
			wantArgs:    []string{},
			wantErr:     false,
		},
		{
			name:    "help alias",
			args:    []string{"help"},
			wantErr: true,
		},
		{
			name:    "missing command",
			args:    []string{},
			wantErr: true,
		},
		{
			name:    "unknown command",
			args:    []string{"status"},
			wantErr: true,
		},
	}

	for _, tc := range tests {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			got, err := parseArgs(tc.args)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("expected error for args %v", tc.args)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if got.command != tc.wantCommand {
				t.Fatalf("command mismatch: got %q want %q", got.command, tc.wantCommand)
			}
			if got.runtime != tc.wantRuntime {
				t.Fatalf("runtime mismatch: got %q want %q", got.runtime, tc.wantRuntime)
			}

			if len(got.passthrough) != len(tc.wantArgs) {
				t.Fatalf("arg length mismatch: got %d want %d", len(got.passthrough), len(tc.wantArgs))
			}
			for i := range got.passthrough {
				if got.passthrough[i] != tc.wantArgs[i] {
					t.Fatalf("arg %d mismatch: got %q want %q", i, got.passthrough[i], tc.wantArgs[i])
				}
			}
		})
	}
}

func TestParseArgsRuntimeFromEnv(t *testing.T) {
	original := os.Getenv("TOOL_SHED_RUNTIME")
	defer func() {
		if original == "" {
			_ = os.Unsetenv("TOOL_SHED_RUNTIME")
			return
		}
		_ = os.Setenv("TOOL_SHED_RUNTIME", original)
	}()

	if err := os.Setenv("TOOL_SHED_RUNTIME", "go"); err != nil {
		t.Fatalf("set env: %v", err)
	}

	got, err := parseArgs([]string{"list"})
	if err != nil {
		t.Fatalf("parse args: %v", err)
	}
	if got.runtime != "go" {
		t.Fatalf("runtime mismatch: got %q want %q", got.runtime, "go")
	}
}

func TestFindRepoRootFromNestedDirectory(t *testing.T) {
	t.Parallel()

	tmpDir := t.TempDir()
	root := filepath.Join(tmpDir, "tool-shed")
	nested := filepath.Join(root, "cmd", "tool-shed")

	if err := os.MkdirAll(nested, 0o755); err != nil {
		t.Fatalf("create nested directory: %v", err)
	}

	required := []string{"install.sh", "update.sh", "uninstall.sh", "list.sh"}
	for _, script := range required {
		path := filepath.Join(root, script)
		if err := os.WriteFile(path, []byte("#!/usr/bin/env bash\n"), 0o755); err != nil {
			t.Fatalf("write %s: %v", script, err)
		}
	}

	got, err := findRepoRoot(nested)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got != root {
		t.Fatalf("repo root mismatch: got %q want %q", got, root)
	}
}

func TestFindRepoRootNotFound(t *testing.T) {
	t.Parallel()

	tmpDir := t.TempDir()
	if _, err := findRepoRoot(tmpDir); err == nil {
		t.Fatal("expected error when root scripts are missing")
	}
}

func TestRunInstallGoRuntimeDryRun(t *testing.T) {
	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	text, runErr := captureStdout(t, func() error {
		return runInstallGoRuntime(repoRoot, []string{"go-ai", "python-ai", "--dry-run"})
	})

	if runErr != nil {
		t.Fatalf("run install go runtime dry-run: %v", runErr)
	}

	if !strings.Contains(text, "DRY RUN: would install the following packages/tools:") {
		t.Fatalf("missing dry-run header in output: %q", text)
	}
	if !strings.Contains(text, "  - golang") {
		t.Fatalf("expected canonicalized golang target in output: %q", text)
	}
	if !strings.Contains(text, "  - python3") {
		t.Fatalf("expected canonicalized python3 target in output: %q", text)
	}
}

func TestRunUpdateGoRuntimeDryRunTargets(t *testing.T) {
	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	text, runErr := captureStdout(t, func() error {
		return runUpdateGoRuntime(repoRoot, []string{"cloud", "--dry-run"})
	})
	if runErr != nil {
		t.Fatalf("run update go runtime dry-run: %v", runErr)
	}
	if !strings.Contains(text, "DRY RUN: would update the following tools:") {
		t.Fatalf("missing update dry-run header: %q", text)
	}
	if !strings.Contains(text, "  - gcloud") {
		t.Fatalf("expected resolved cloud targets in output: %q", text)
	}
}

func TestRunUpdateGoRuntimeDryRunNoTargets(t *testing.T) {
	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	text, runErr := captureStdout(t, func() error {
		return runUpdateGoRuntime(repoRoot, []string{"--dry-run"})
	})
	if runErr != nil {
		t.Fatalf("run update go runtime dry-run: %v", runErr)
	}
	if !strings.Contains(text, "DRY RUN: would update all managed, installed tools from state.") {
		t.Fatalf("missing no-target update dry-run message: %q", text)
	}
}

func TestRunUninstallGoRuntimeDryRunRequiresTarget(t *testing.T) {
	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	_, runErr := captureStdout(t, func() error {
		return runUninstallGoRuntime(repoRoot, []string{"--dry-run"})
	})
	if runErr == nil {
		t.Fatal("expected uninstall dry-run without target to fail")
	}
}

func TestRunListGoRuntimeWithTargets(t *testing.T) {
	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	text, runErr := captureStdout(t, func() error {
		return runListGoRuntime(repoRoot, []string{"cloud"})
	})
	if runErr != nil {
		t.Fatalf("run list go runtime with targets: %v", runErr)
	}
	if !strings.Contains(text, "Resolved list targets:") {
		t.Fatalf("missing list resolved header: %q", text)
	}
	if !strings.Contains(text, "  - aws") {
		t.Fatalf("missing resolved list targets in output: %q", text)
	}
}
