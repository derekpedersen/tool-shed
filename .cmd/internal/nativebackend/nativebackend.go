package nativebackend

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"

	"github.com/derekpedersen/tool-shed/.cmd/internal/catalog"
)

var ErrNoSupportedTools = errors.New("native backend has no supported tools for this request")

var hostOS = runtime.GOOS

type Backend struct {
	catalog *catalog.Catalog
}

func New(c *catalog.Catalog) *Backend {
	return &Backend{catalog: c}
}

func (b *Backend) Supports(tool string) bool {
	_, ok := b.supportedSpec(tool)
	return ok
}

func (b *Backend) Install(tools []string, dryRun bool) error {
	handled := 0
	for _, tool := range tools {
		spec, ok := b.supportedSpec(tool)
		if !ok {
			fmt.Fprintf(os.Stdout, "SKIPPED native backend unsupported tool: %s\n", tool)
			continue
		}
		handled++
		name, args := commandForSpec(spec, "install")
		if dryRun {
			fmt.Fprintf(os.Stdout, "DRY RUN: would run: %s %s\n", name, strings.Join(args, " "))
			continue
		}
		if err := runCommand(name, args...); err != nil {
			return fmt.Errorf("install %s: %w", tool, err)
		}
	}
	if handled == 0 {
		return ErrNoSupportedTools
	}
	return nil
}

func (b *Backend) Update(tools []string, dryRun bool) error {
	handled := 0
	for _, tool := range tools {
		spec, ok := b.supportedSpec(tool)
		if !ok {
			fmt.Fprintf(os.Stdout, "SKIPPED native backend unsupported tool: %s\n", tool)
			continue
		}
		handled++
		name, args := commandForSpec(spec, "update")
		if dryRun {
			fmt.Fprintf(os.Stdout, "DRY RUN: would run: %s %s\n", name, strings.Join(args, " "))
			continue
		}
		if err := runCommand(name, args...); err != nil {
			return fmt.Errorf("update %s: %w", tool, err)
		}
	}
	if handled == 0 {
		return ErrNoSupportedTools
	}
	return nil
}

func (b *Backend) Uninstall(tools []string, dryRun bool) error {
	handled := 0
	for _, tool := range tools {
		spec, ok := b.supportedSpec(tool)
		if !ok {
			fmt.Fprintf(os.Stdout, "SKIPPED native backend unsupported tool: %s\n", tool)
			continue
		}
		handled++
		name, args := commandForSpec(spec, "uninstall")
		if dryRun {
			fmt.Fprintf(os.Stdout, "DRY RUN: would run: %s %s\n", name, strings.Join(args, " "))
			continue
		}
		if err := runCommand(name, args...); err != nil {
			return fmt.Errorf("uninstall %s: %w", tool, err)
		}
	}
	if handled == 0 {
		return ErrNoSupportedTools
	}
	return nil
}

func (b *Backend) List(tools []string) error {
	handled := 0
	fmt.Fprintf(os.Stdout, "%-18s %-24s %s\n", "TOOL", "PACKAGE", "MANAGER")
	fmt.Fprintf(os.Stdout, "%-18s %-24s %s\n", "------------------", "------------------------", "----------------")
	for _, tool := range tools {
		spec, ok := b.supportedSpec(tool)
		if !ok {
			fmt.Fprintf(os.Stdout, "%-18s %-24s %s\n", tool, "unknown", "unsupported")
			continue
		}
		handled++
		fmt.Fprintf(os.Stdout, "%-18s %-24s %s\n", tool, spec.Package, spec.Manager)
	}
	if handled == 0 {
		return ErrNoSupportedTools
	}
	return nil
}

func (b *Backend) supportedSpec(tool string) (catalog.ToolSpec, bool) {
	specs := b.catalog.ToolSpecs[tool]
	for _, spec := range specs {
		if (hostOS == "darwin" && (spec.Manager == "brew-formula" || spec.Manager == "brew-cask")) ||
			(hostOS == "linux" && spec.Manager == "apt") ||
			(hostOS == "windows" && (spec.Manager == "winget" || spec.Manager == "winget-store")) {
			return spec, true
		}
	}
	return catalog.ToolSpec{}, false
}

func commandForSpec(spec catalog.ToolSpec, operation string) (string, []string) {
	switch spec.Manager {
	case "brew-formula", "brew-cask":
		return brewCommand(spec, operation)
	case "apt":
		return aptCommand(spec, operation)
	case "winget", "winget-store":
		return wingetCommand(spec, operation)
	default:
		return "", nil
	}
}

func brewCommand(spec catalog.ToolSpec, operation string) (string, []string) {
	args := []string{}
	switch operation {
	case "install":
		args = append(args, "install")
	case "update":
		args = append(args, "upgrade")
	case "uninstall":
		args = append(args, "uninstall", "--force")
	}
	if spec.Manager == "brew-cask" {
		args = append(args, "--cask")
	}
	args = append(args, spec.Package)
	return "brew", args
}

func aptCommand(spec catalog.ToolSpec, operation string) (string, []string) {
	args := []string{}
	switch operation {
	case "install":
		args = []string{"install", "-y", spec.Package}
	case "update":
		args = []string{"install", "--only-upgrade", "-y", spec.Package}
	case "uninstall":
		args = []string{"remove", "-y", spec.Package}
	}
	return "apt-get", args
}

func wingetCommand(spec catalog.ToolSpec, operation string) (string, []string) {
	args := []string{}
	common := []string{"--exact", "--id", spec.Package}
	if spec.Source != "" {
		common = append(common, "--source", spec.Source)
	}

	switch operation {
	case "install":
		args = []string{"install"}
		args = append(args, common...)
		args = append(args, "--accept-source-agreements", "--accept-package-agreements")
	case "update":
		args = []string{"upgrade"}
		args = append(args, common...)
		args = append(args, "--accept-source-agreements", "--accept-package-agreements")
	case "uninstall":
		args = []string{"uninstall"}
		args = append(args, common...)
	}

	return "winget", args
}

func runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Env = os.Environ()
	return cmd.Run()
}
