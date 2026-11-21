package catalog

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

	c, err := Load(repoRoot)
	if err != nil {
		t.Fatalf("load catalog: %v", err)
	}
	if len(c.ToolSpecs) == 0 {
		t.Fatal("expected tool specs to be populated")
	}
	if len(c.ToolSpecs["golang"]) == 0 {
		t.Fatal("expected golang specs to be present")
	}
}
