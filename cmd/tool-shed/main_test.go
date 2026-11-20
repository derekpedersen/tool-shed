package main

import (
	"os"
	"path/filepath"
	"testing"
)

func TestParseArgs(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name        string
		args        []string
		wantCommand string
		wantArgs    []string
		wantErr     bool
	}{
		{
			name:        "install with passthrough",
			args:        []string{"install", "cloud", "--dry-run"},
			wantCommand: "install",
			wantArgs:    []string{"cloud", "--dry-run"},
			wantErr:     false,
		},
		{
			name:        "list with no extra args",
			args:        []string{"list"},
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

			gotCommand, gotArgs, err := parseArgs(tc.args)
			if tc.wantErr {
				if err == nil {
					t.Fatalf("expected error for args %v", tc.args)
				}
				return
			}

			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			if gotCommand != tc.wantCommand {
				t.Fatalf("command mismatch: got %q want %q", gotCommand, tc.wantCommand)
			}

			if len(gotArgs) != len(tc.wantArgs) {
				t.Fatalf("arg length mismatch: got %d want %d", len(gotArgs), len(tc.wantArgs))
			}
			for i := range gotArgs {
				if gotArgs[i] != tc.wantArgs[i] {
					t.Fatalf("arg %d mismatch: got %q want %q", i, gotArgs[i], tc.wantArgs[i])
				}
			}
		})
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
