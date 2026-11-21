package state

import (
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"testing"
)

func TestParseAndFormatRoundTrip(t *testing.T) {
	t.Parallel()

	line := "brew-formula\tgo\t-\tfull\t/opt/homebrew/bin/go\tgo1.24.0\n"
	record, err := ParseToolRecord(line)
	if err != nil {
		t.Fatalf("parse record: %v", err)
	}
	formatted, err := record.Format()
	if err != nil {
		t.Fatalf("format record: %v", err)
	}
	if formatted != line {
		t.Fatalf("round trip mismatch\n got: %q\nwant: %q", formatted, line)
	}
}

func TestWriteAndReadToolRecord(t *testing.T) {
	t.Parallel()

	tmp := t.TempDir()
	path := filepath.Join(tmp, "tools", "golang")
	in := ToolRecord{
		Manager: "brew-formula",
		Package: "go",
		Source:  "-",
		Profile: "full",
		Path:    "/opt/homebrew/bin/go",
		Version: "go1.24.0",
	}
	if err := WriteToolRecord(path, in); err != nil {
		t.Fatalf("write record: %v", err)
	}
	out, err := ReadToolRecord(path)
	if err != nil {
		t.Fatalf("read record: %v", err)
	}
	if !reflect.DeepEqual(in, out) {
		t.Fatalf("record mismatch\n got: %#v\nwant: %#v", out, in)
	}
}

func TestListToolRecordNames(t *testing.T) {
	t.Parallel()

	tmp := t.TempDir()
	toolsDir := filepath.Join(tmp, "tools")
	if err := os.MkdirAll(toolsDir, 0o755); err != nil {
		t.Fatalf("create tools dir: %v", err)
	}
	if err := os.WriteFile(filepath.Join(toolsDir, "golang"), []byte("x\n"), 0o644); err != nil {
		t.Fatalf("write golang record: %v", err)
	}
	if err := os.WriteFile(filepath.Join(toolsDir, "node"), []byte("x\n"), 0o644); err != nil {
		t.Fatalf("write node record: %v", err)
	}
	if err := os.WriteFile(filepath.Join(toolsDir, "bad.name"), []byte("x\n"), 0o644); err != nil {
		t.Fatalf("write invalid record: %v", err)
	}

	names, err := ListToolRecordNames(tmp)
	if err != nil {
		t.Fatalf("list names: %v", err)
	}
	want := []string{"golang", "node"}
	if !reflect.DeepEqual(names, want) {
		t.Fatalf("name list mismatch\n got: %v\nwant: %v", names, want)
	}
}

func TestStateCompatibilityGoWriteShellRead(t *testing.T) {
	t.Parallel()

	tmp := t.TempDir()
	repoRoot, err := filepath.Abs(filepath.Join("..", "..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}
	stateScript := filepath.Join(repoRoot, ".tools", "state.sh")

	record := ToolRecord{
		Manager: "brew-formula",
		Package: "go",
		Source:  "-",
		Profile: "full",
		Path:    "/opt/homebrew/bin/go",
		Version: "go1.24.0",
	}
	recordPath := filepath.Join(tmp, "tools", "golang")
	if err := WriteToolRecord(recordPath, record); err != nil {
		t.Fatalf("write go record: %v", err)
	}

	cmd := exec.Command(
		"bash", "-lc",
		`source "$1"; TOOL_SHED_STATE_DIR="$2"; tool_state_read golang; printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$STATE_MANAGER" "$STATE_PACKAGE" "$STATE_SOURCE" "$STATE_PROFILE" "$STATE_PATH" "$STATE_VERSION"`,
		"_", stateScript, tmp,
	)
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("shell state read failed: %v", err)
	}
	want, err := record.Format()
	if err != nil {
		t.Fatalf("format expected record: %v", err)
	}
	if string(out) != want {
		t.Fatalf("shell read mismatch\n got: %q\nwant: %q", string(out), want)
	}
}

func TestStateCompatibilityShellWriteGoRead(t *testing.T) {
	t.Parallel()

	tmp := t.TempDir()
	repoRoot, err := filepath.Abs(filepath.Join("..", "..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}
	stateScript := filepath.Join(repoRoot, ".tools", "state.sh")

	cmd := exec.Command(
		"bash", "-lc",
		`source "$1"; TOOL_SHED_STATE_DIR="$2"; mkdir -p "$(tool_state_dir)/tools"; printf '%s	%s	%s	%s	%s	%s
' apt wget - none /usr/bin/wget 1.21.3 > "$(tool_state_dir)/tools/wget"`,
		"_", stateScript, tmp,
	)
	if out, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("shell state write failed: %v: %s", err, string(out))
	}

	recordPath := filepath.Join(tmp, "tools", "wget")
	record, err := ReadToolRecord(recordPath)
	if err != nil {
		t.Fatalf("go state read failed: %v", err)
	}

	want := ToolRecord{
		Manager: "apt",
		Package: "wget",
		Source:  "-",
		Profile: "none",
		Path:    "/usr/bin/wget",
		Version: "1.21.3",
	}
	if !reflect.DeepEqual(record, want) {
		t.Fatalf("go read mismatch\n got: %#v\nwant: %#v", record, want)
	}
}
