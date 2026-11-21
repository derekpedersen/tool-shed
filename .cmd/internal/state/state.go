package state

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
)

const fieldCount = 6

type ToolRecord struct {
	Manager string
	Package string
	Source  string
	Profile string
	Path    string
	Version string
}

func ValidName(name string) bool {
	if name == "" {
		return false
	}
	for _, ch := range name {
		if (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '-' {
			continue
		}
		return false
	}
	return true
}

func ParseToolRecord(line string) (ToolRecord, error) {
	line = strings.TrimSuffix(line, "\n")
	parts := strings.Split(line, "\t")
	if len(parts) != fieldCount {
		return ToolRecord{}, fmt.Errorf("expected %d tab-separated fields, got %d", fieldCount, len(parts))
	}
	record := ToolRecord{
		Manager: parts[0],
		Package: parts[1],
		Source:  parts[2],
		Profile: parts[3],
		Path:    parts[4],
		Version: parts[5],
	}
	if record.Manager == "" || record.Version == "" {
		return ToolRecord{}, errors.New("record manager and version must be present")
	}
	return record, nil
}

func (r ToolRecord) Format() (string, error) {
	fields := []string{r.Manager, r.Package, r.Source, r.Profile, r.Path, r.Version}
	for _, field := range fields {
		if strings.ContainsAny(field, "\t\n") {
			return "", errors.New("record fields must not contain tab or newline")
		}
	}
	return strings.Join(fields, "\t") + "\n", nil
}

func ReadToolRecord(path string) (ToolRecord, error) {
	content, err := os.ReadFile(path)
	if err != nil {
		return ToolRecord{}, err
	}
	return ParseToolRecord(string(content))
}

func WriteToolRecord(path string, record ToolRecord) error {
	formatted, err := record.Format()
	if err != nil {
		return err
	}
	dir := filepath.Dir(path)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return err
	}
	tmp, err := os.CreateTemp(dir, ".record.*")
	if err != nil {
		return err
	}
	tmpPath := tmp.Name()
	defer func() {
		_ = os.Remove(tmpPath)
	}()
	if _, err := tmp.WriteString(formatted); err != nil {
		_ = tmp.Close()
		return err
	}
	if err := tmp.Close(); err != nil {
		return err
	}
	return os.Rename(tmpPath, path)
}

func ListToolRecordNames(stateDir string) ([]string, error) {
	toolsDir := filepath.Join(stateDir, "tools")
	entries, err := os.ReadDir(toolsDir)
	if err != nil {
		if os.IsNotExist(err) {
			return []string{}, nil
		}
		return nil, err
	}

	names := make([]string, 0, len(entries))
	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}
		name := entry.Name()
		if !ValidName(name) {
			continue
		}
		names = append(names, name)
	}
	sort.Strings(names)
	return names, nil
}
