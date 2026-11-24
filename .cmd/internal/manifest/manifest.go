package manifest

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
)

// Manifest stores shared tool resolution definitions exported from shell runtime.
type Manifest struct {
	Bundles     map[string][]string `json:"bundles"`
	BundleOrder []string            `json:"bundleOrder"`
	Aliases     map[string]string   `json:"aliases"`
	Expansions  map[string][]string `json:"expansions"`
}

type bundleEntry struct {
	Key int `json:"key"`
}

type bundleDefinition struct {
	Key          int                    `json:"key"`
	FriendlyName string                 `json:"friendlyName"`
	Description  string                 `json:"description"`
	Tools        map[string]bundleEntry `json:"tools"`
}

type toolInfo struct {
	DisplayName string   `json:"displayName"`
	Description string   `json:"description"`
	Aliases     []string `json:"aliases"`
	ExpandsTo   []string `json:"expandsTo"`
}

type configCatalog struct {
	Tools            map[string]toolInfo         `json:"tools"`
	Bundles          map[string]bundleDefinition `json:"bundles"`
	AliasesLegacy    map[string]string           `json:"aliases"`
	ExpansionsLegacy map[string][]string         `json:"expansions"`
}

func Load(repoRoot string) (*Manifest, error) {
	catalogPath := filepath.Join(repoRoot, ".config", "catalog.json")
	rawCatalog, err := os.ReadFile(catalogPath)
	if err != nil {
		return nil, fmt.Errorf("read catalog json: %w", err)
	}

	var catalog configCatalog
	if err := json.Unmarshal(rawCatalog, &catalog); err != nil {
		return nil, fmt.Errorf("parse catalog json: %w", err)
	}

	var m Manifest
	m.Bundles = map[string][]string{}
	m.BundleOrder = []string{}

	bundleNamesByOrder := map[int]string{}
	bundleOrders := make([]int, 0, len(catalog.Bundles))
	for bundleName, bundleDef := range catalog.Bundles {
		if bundleDef.Key < 0 {
			return nil, fmt.Errorf("bundle %s has invalid key: %d", bundleName, bundleDef.Key)
		}
		if _, exists := bundleNamesByOrder[bundleDef.Key]; exists {
			return nil, fmt.Errorf("duplicate bundle key %d", bundleDef.Key)
		}
		bundleNamesByOrder[bundleDef.Key] = bundleName
		bundleOrders = append(bundleOrders, bundleDef.Key)
	}

	sort.Ints(bundleOrders)
	for expected, order := range bundleOrders {
		if order != expected {
			return nil, fmt.Errorf("bundle keys must be contiguous from 0; expected %d got %d", expected, order)
		}
		m.BundleOrder = append(m.BundleOrder, bundleNamesByOrder[order])
	}

	for _, bundleName := range m.BundleOrder {
		rawEntries := catalog.Bundles[bundleName].Tools
		entriesByOrder := map[int]string{}
		orders := make([]int, 0, len(rawEntries))
		for toolKey, entry := range rawEntries {
			order := entry.Key
			if order < 0 {
				return nil, fmt.Errorf("bundle %s has invalid key for tool %q: %d", bundleName, toolKey, order)
			}
			if toolKey == "" {
				return nil, fmt.Errorf("bundle %s has empty tool key at key %d", bundleName, order)
			}
			if _, exists := entriesByOrder[order]; exists {
				return nil, fmt.Errorf("bundle %s has duplicate numeric key %d", bundleName, order)
			}
			entriesByOrder[order] = toolKey
			orders = append(orders, order)
		}

		sort.Ints(orders)
		for expected, order := range orders {
			if order != expected {
				return nil, fmt.Errorf("bundle %s keys must be contiguous from 0; expected %d got %d", bundleName, expected, order)
			}
		}

		items := make([]string, 0, len(orders))
		for _, order := range orders {
			item := entriesByOrder[order]
			if _, ok := catalog.Tools[item]; !ok {
				return nil, fmt.Errorf("bundle %s references unknown tool key %q", bundleName, item)
			}
			items = append(items, item)
		}
		m.Bundles[bundleName] = items
	}

	m.Aliases = map[string]string{}
	for canonical, info := range catalog.Tools {
		for _, alias := range info.Aliases {
			m.Aliases[alias] = canonical
		}
	}
	for alias, canonical := range catalog.AliasesLegacy {
		if _, exists := m.Aliases[alias]; !exists {
			m.Aliases[alias] = canonical
		}
	}
	m.Expansions = map[string][]string{}
	for selector, info := range catalog.Tools {
		if len(info.ExpandsTo) == 0 {
			continue
		}
		m.Expansions[selector] = append([]string{}, info.ExpandsTo...)
	}
	for selector, items := range catalog.ExpansionsLegacy {
		if _, exists := m.Expansions[selector]; !exists {
			m.Expansions[selector] = append([]string{}, items...)
		}
	}
	if m.Expansions == nil {
		m.Expansions = map[string][]string{}
	}
	for bundleName, items := range m.Bundles {
		if _, exists := m.Expansions[bundleName]; !exists {
			m.Expansions[bundleName] = items
		}
	}
	for bundleKey, bundleName := range bundleNamesByOrder {
		selector := strconv.Itoa(bundleKey)
		if _, exists := m.Expansions[selector]; !exists {
			m.Expansions[selector] = append([]string{}, m.Bundles[bundleName]...)
		}
	}
	for expansion, items := range m.Expansions {
		for _, item := range items {
			if _, ok := catalog.Tools[item]; !ok {
				return nil, fmt.Errorf("expansion %s references unknown tool key %q", expansion, item)
			}
		}
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
