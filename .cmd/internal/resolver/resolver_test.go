package resolver

import (
	"bytes"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"

	"github.com/derekpedersen/tool-shed/.cmd/internal/manifest"
)

func resolveWithShell(t *testing.T, repoRoot string, targets []string) []string {
	t.Helper()

	commonPath := filepath.Join(repoRoot, ".tools", "common.sh")
	script := `source "$1"; shift; resolve_target_tools "$@"`
	args := []string{"-lc", script, "_", commonPath}
	args = append(args, targets...)

	cmd := exec.Command("bash", args...)
	out, err := cmd.Output()
	if err != nil {
		t.Fatalf("resolve with shell failed: %v", err)
	}
	trimmed := strings.TrimSpace(string(out))
	if trimmed == "" {
		return []string{}
	}
	return strings.Split(trimmed, "\n")
}

func loadManifestForTest(t *testing.T) *manifest.Manifest {
	t.Helper()
	repoRoot := filepath.Join("..", "..", "..")
	repoRoot, err := filepath.Abs(repoRoot)
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}
	if _, err := os.Stat(filepath.Join(repoRoot, ".tools", "export-manifest.sh")); err != nil {
		t.Fatalf("missing export-manifest.sh: %v", err)
	}
	m, err := manifest.Load(repoRoot)
	if err != nil {
		t.Fatalf("load manifest: %v", err)
	}
	return m
}

func TestResolveBundleFull(t *testing.T) {
	t.Parallel()

	m := loadManifestForTest(t)
	got := Resolve(m, []string{"full"})
	want := m.Bundles["full"]
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("full bundle mismatch\n got: %v\nwant: %v", got, want)
	}
}

func TestResolveAliasesAndDedup(t *testing.T) {
	t.Parallel()

	m := loadManifestForTest(t)
	got := Resolve(m, []string{"go-ai", "python-ai", "node-core", "golang", "go"})
	want := []string{"golang", "python3", "node"}
	if !reflect.DeepEqual(got, want) {
		t.Fatalf("alias resolution mismatch\n got: %v\nwant: %v", got, want)
	}
}

func TestResolveMixedOrder(t *testing.T) {
	t.Parallel()

	m := loadManifestForTest(t)
	got := Resolve(m, []string{"cloud", "awscli", "google-cloud", "azure-cli"})
	if len(got) == 0 {
		t.Fatal("expected resolved targets")
	}

	positions := map[string]int{}
	for i, item := range got {
		positions[item] = i
	}
	if positions["aws"] < 0 || positions["gcloud"] < 0 || positions["az"] < 0 {
		t.Fatalf("missing canonical tools in result: %v", got)
	}
	if positions["gcloud"] > positions["aws"] {
		t.Fatalf("expected gcloud to appear before aws based on cloud bundle order: %v", got)
	}
}

func TestResolveParityWithShell(t *testing.T) {
	t.Parallel()

	repoRoot, err := filepath.Abs(filepath.Join("..", "..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}
	m := loadManifestForTest(t)

	cases := [][]string{
		{"full"},
		{"cloud", "awscli", "go-ai", "python-ai"},
		{"services", "postgres", "redis"},
		{"software-developer", "kubernetes-cli", "digitalocean"},
		{"data-science", "R", "python-full", "node-core"},
		{"go", "golang", "go-ai", "go-core", "go-full"},
	}

	for _, tc := range cases {
		tc := tc
		t.Run(strings.Join(tc, "+"), func(t *testing.T) {
			t.Parallel()
			goResolved := Resolve(m, tc)
			shellResolved := resolveWithShell(t, repoRoot, tc)
			if !reflect.DeepEqual(goResolved, shellResolved) {
				var b bytes.Buffer
				b.WriteString("resolver drift detected\n")
				b.WriteString("input: ")
				b.WriteString(strings.Join(tc, " "))
				b.WriteString("\n")
				b.WriteString("go: ")
				b.WriteString(strings.Join(goResolved, ","))
				b.WriteString("\n")
				b.WriteString("shell: ")
				b.WriteString(strings.Join(shellResolved, ","))
				t.Fatal(b.String())
			}
		})
	}
}
