package manifest

import (
	"path/filepath"
	"testing"
)

func TestLoad(t *testing.T) {
	t.Parallel()

	repoRoot, err := filepath.Abs(filepath.Join("..", "..", ".."))
	if err != nil {
		t.Fatalf("resolve repo root: %v", err)
	}

	m, err := Load(repoRoot)
	if err != nil {
		t.Fatalf("load manifest: %v", err)
	}
	if len(m.Bundles["full"]) == 0 {
		t.Fatal("expected full bundle to be populated")
	}
	if m.Aliases["awscli"] != "aws" {
		t.Fatalf("expected awscli alias to map to aws, got %q", m.Aliases["awscli"])
	}
	if len(m.Expansions["cloud"]) == 0 {
		t.Fatal("expected cloud expansion to be populated")
	}
}
