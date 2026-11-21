package catalog

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
)

type ToolSpec struct {
	Manager string `json:"manager"`
	Package string `json:"package"`
	Source  string `json:"source"`
}

type Catalog struct {
	Platform  string                `json:"platform"`
	ToolSpecs map[string][]ToolSpec `json:"toolSpecs"`
}

func Load(repoRoot string) (*Catalog, error) {
	scriptPath := filepath.Join(repoRoot, ".tools", "export-catalog.sh")
	out, err := exec.Command("bash", scriptPath).Output()
	if err != nil {
		return nil, fmt.Errorf("export shared catalog: %w", err)
	}

	var c Catalog
	if err := json.Unmarshal(out, &c); err != nil {
		return nil, fmt.Errorf("parse shared catalog json: %w", err)
	}
	if c.ToolSpecs == nil {
		c.ToolSpecs = map[string][]ToolSpec{}
	}
	return &c, nil
}
