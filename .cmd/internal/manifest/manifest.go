package manifest

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"path/filepath"
)

// Manifest stores shared tool resolution definitions exported from shell runtime.
type Manifest struct {
	Bundles    map[string][]string `json:"bundles"`
	Aliases    map[string]string   `json:"aliases"`
	Expansions map[string][]string `json:"expansions"`
}

func Load(repoRoot string) (*Manifest, error) {
	scriptPath := filepath.Join(repoRoot, ".tools", "export-manifest.sh")
	out, err := exec.Command("bash", scriptPath).Output()
	if err != nil {
		return nil, fmt.Errorf("export shared manifest: %w", err)
	}

	var m Manifest
	if err := json.Unmarshal(out, &m); err != nil {
		return nil, fmt.Errorf("parse shared manifest json: %w", err)
	}
	if m.Bundles == nil {
		m.Bundles = map[string][]string{}
	}
	if m.Aliases == nil {
		m.Aliases = map[string]string{}
	}
	if m.Expansions == nil {
		m.Expansions = map[string][]string{}
	}
	return &m, nil
}
