package main

import (
	"bytes"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/derekpedersen/tool-shed/.cmd/internal/catalog"
	"github.com/derekpedersen/tool-shed/.cmd/internal/nativebackend"
	"github.com/derekpedersen/tool-shed/.cmd/internal/state"
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
	originalBackend := os.Getenv("TOOL_SHED_BACKEND")
	defer func() {
		if original == "" {
			_ = os.Unsetenv("TOOL_SHED_RUNTIME")
		} else {
			_ = os.Setenv("TOOL_SHED_RUNTIME", original)
		}
		if originalBackend == "" {
			_ = os.Unsetenv("TOOL_SHED_BACKEND")
		} else {
			_ = os.Setenv("TOOL_SHED_BACKEND", originalBackend)
		}
	}()

	if err := os.Setenv("TOOL_SHED_RUNTIME", "go"); err != nil {
		t.Fatalf("set env: %v", err)
	}
	if err := os.Setenv("TOOL_SHED_BACKEND", "native"); err != nil {
		t.Fatalf("set env: %v", err)
	}

	got, err := parseArgs([]string{"list"})
	if err != nil {
		t.Fatalf("parse args: %v", err)
	}
	if got.runtime != "go" {
		t.Fatalf("runtime mismatch: got %q want %q", got.runtime, "go")
	}
	if got.backend != "native" {
		t.Fatalf("backend mismatch: got %q want %q", got.backend, "native")
	}
}

func TestParseArgsBackendFlag(t *testing.T) {
	t.Parallel()

	got, err := parseArgs([]string{"--runtime=go", "--backend=native", "install", "cloud"})
	if err != nil {
		t.Fatalf("parse args: %v", err)
	}
	if got.runtime != "go" {
		t.Fatalf("runtime mismatch: got %q want go", got.runtime)
	}
	if got.backend != "native" {
		t.Fatalf("backend mismatch: got %q want native", got.backend)
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

func TestParseNativeOptions(t *testing.T) {
	t.Parallel()

	opts := parseNativeOptions([]string{"--dry-run", "--allow-major", "--include-services", "--yes", "cloud", "--with-packages"})
	if !opts.dryRun || !opts.allowMajor || !opts.includeServices || !opts.yes || !opts.withPackages {
		t.Fatalf("unexpected option flags: %#v", opts)
	}
	if len(opts.targets) != 1 || opts.targets[0] != "cloud" {
		t.Fatalf("unexpected targets: %#v", opts.targets)
	}
}

func TestFilterNativeUpdateTargetsPolicySkips(t *testing.T) {
	t.Parallel()

	stateDir := t.TempDir()
	write := func(name string) {
		t.Helper()
		recordPath := filepath.Join(stateDir, "tools", name)
		err := state.WriteToolRecord(recordPath, state.ToolRecord{
			Manager: "brew-formula",
			Package: name,
			Source:  "-",
			Profile: "full",
			Path:    "/usr/local/bin/" + name,
			Version: "1.0.0",
		})
		if err != nil {
			t.Fatalf("write state record %s: %v", name, err)
		}
	}

	write("postgres")
	write("julia")
	write("gh")

	if err := os.MkdirAll(filepath.Join(stateDir, "pins"), 0o755); err != nil {
		t.Fatalf("create pins dir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(stateDir, "pins", "gh"), []byte(""), 0o644); err != nil {
		t.Fatalf("write pin file: %v", err)
	}

	opts := nativeOptions{}
	output, err := captureStdout(t, func() error {
		eligible, filterErr := filterNativeUpdateTargets(stateDir, []string{"postgres", "julia", "gh", "kubectl"}, opts)
		if filterErr != nil {
			return filterErr
		}
		if len(eligible) != 0 {
			t.Fatalf("expected all targets to be skipped, got: %v", eligible)
		}
		return nil
	})
	if err != nil {
		t.Fatalf("filter targets: %v", err)
	}

	checks := []string{
		"requires --include-services --yes",
		"Julia updates require --allow-major",
		"is pinned in the tool-shed state directory",
		"is not managed",
	}
	for _, check := range checks {
		if !strings.Contains(output, check) {
			t.Fatalf("expected output to contain %q, got: %q", check, output)
		}
	}
}

func TestRunNativeBackendListNoTargetsNoManaged(t *testing.T) {
	stateDir := t.TempDir()

	originalStateDir := os.Getenv("TOOL_SHED_STATE_DIR")
	defer func() {
		if originalStateDir == "" {
			_ = os.Unsetenv("TOOL_SHED_STATE_DIR")
		} else {
			_ = os.Setenv("TOOL_SHED_STATE_DIR", originalStateDir)
		}
	}()
	if err := os.Setenv("TOOL_SHED_STATE_DIR", stateDir); err != nil {
		t.Fatalf("set state dir env: %v", err)
	}

	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	output, runErr := captureStdout(t, func() error {
		return runNativeBackend(repoRoot, "list", nil)
	})
	if runErr != nil {
		t.Fatalf("run native list: %v", runErr)
	}
	if !strings.Contains(output, "No managed tools recorded") {
		t.Fatalf("expected no-managed message, got: %q", output)
	}
}

func TestAllNativeSupported(t *testing.T) {
	t.Parallel()

	b := nativebackend.New(&catalog.Catalog{
		ToolSpecs: map[string][]catalog.ToolSpec{
			"gh":      []catalog.ToolSpec{{Manager: "brew-formula", Package: "gh"}},
			"kubectl": []catalog.ToolSpec{{Manager: "direct", Package: "kubectl"}},
		},
	})

	if !allNativeSupported(b, []string{"gh"}) {
		t.Fatal("expected gh to be native-supported on this host")
	}
	if allNativeSupported(b, []string{"gh", "kubectl"}) {
		t.Fatal("expected mixed support set to be unsupported")
	}
}

func TestRunNativeBackendUpdateWithPackagesRequestsFallback(t *testing.T) {
	repoRoot, err := filepath.Abs(filepath.Join("..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	err = runNativeBackend(repoRoot, "update", []string{"--with-packages", "gh"})
	if !errors.Is(err, nativebackend.ErrNoSupportedTools) {
		t.Fatalf("expected ErrNoSupportedTools, got: %v", err)
	}
}
