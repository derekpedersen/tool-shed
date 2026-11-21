package resolver

import "github.com/derekpedersen/tool-shed/.cmd/internal/manifest"

func Resolve(m *manifest.Manifest, targets []string) []string {
	expanded := make([]string, 0, len(targets))
	for _, item := range targets {
		expansions, ok := m.Expansions[item]
		if ok {
			for _, expandedItem := range expansions {
				expanded = append(expanded, canonicalize(m, expandedItem))
			}
			continue
		}
		expanded = append(expanded, canonicalize(m, item))
	}

	result := make([]string, 0, len(expanded))
	seen := map[string]bool{}
	for _, item := range expanded {
		if seen[item] {
			continue
		}
		seen[item] = true
		result = append(result, item)
	}
	return result
}

func canonicalize(m *manifest.Manifest, target string) string {
	if canonical, ok := m.Aliases[target]; ok {
		return canonical
	}
	return target
}
