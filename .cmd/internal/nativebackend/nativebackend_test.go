package nativebackend

import (
	"bytes"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/derekpedersen/tool-shed/.cmd/internal/catalog"
)

func captureStdout(t *testing.T, fn func() error) (string, error) {
	t.Helper()

	originalStdout := os.Stdout
	r, w, err := os.Pipe()
	if err != nil {
		t.Fatalf("create pipe: %v", err)
	}
	os.Stdout = w

	runErr := fn()

	_ = w.Close()
	os.Stdout = originalStdout

	var output bytes.Buffer
	if _, err := output.ReadFrom(r); err != nil {
		t.Fatalf("read captured output: %v", err)
	}
	return output.String(), runErr
}

func withHostOS(t *testing.T, value string) {
	t.Helper()
	original := hostOS
	hostOS = value
	t.Cleanup(func() {
		hostOS = original
	})
}

func TestNativeBackendInstallUnsupportedReturnsNoSupported(t *testing.T) {
	withHostOS(t, "darwin")

	c := &catalog.Catalog{
		Platform: "linux",
		ToolSpecs: map[string][]catalog.ToolSpec{
			"golang": {
				{Manager: "apt", Package: "golang-go"},
			},
		},
	}
	b := New(c)

	err := b.Install([]string{"golang"}, true)
	if !errors.Is(err, ErrNoSupportedTools) {
		t.Fatalf("expected ErrNoSupportedTools, got: %v", err)
	}
}

func TestNativeBackendListUnsupportedReturnsNoSupported(t *testing.T) {
	withHostOS(t, "darwin")

	c := &catalog.Catalog{ToolSpecs: map[string][]catalog.ToolSpec{}}
	b := New(c)

	err := b.List([]string{"does-not-exist"})
	if !errors.Is(err, ErrNoSupportedTools) {
		t.Fatalf("expected ErrNoSupportedTools, got: %v", err)
	}
}

func TestNativeBackendInstallAptDryRun(t *testing.T) {
	withHostOS(t, "linux")

	c := &catalog.Catalog{
		Platform: "linux",
		ToolSpecs: map[string][]catalog.ToolSpec{
			"golang": {
				{Manager: "apt", Package: "golang-go"},
			},
		},
	}
	b := New(c)

	output, err := captureStdout(t, func() error {
		return b.Install([]string{"golang"}, true)
	})
	if err != nil {
		t.Fatalf("install dry-run: %v", err)
	}
	if !strings.Contains(output, "DRY RUN: would run: apt-get install -y golang-go") {
		t.Fatalf("expected apt dry-run command in output, got: %q", output)
	}
}

func TestNativeBackendUpdateAptDryRun(t *testing.T) {
	withHostOS(t, "linux")

	c := &catalog.Catalog{
		Platform: "linux",
		ToolSpecs: map[string][]catalog.ToolSpec{
			"golang": {
				{Manager: "apt", Package: "golang-go"},
			},
		},
	}
	b := New(c)

	output, err := captureStdout(t, func() error {
		return b.Update([]string{"golang"}, true)
	})
	if err != nil {
		t.Fatalf("update dry-run: %v", err)
	}
	if !strings.Contains(output, "DRY RUN: would run: apt-get install --only-upgrade -y golang-go") {
		t.Fatalf("expected apt update dry-run command in output, got: %q", output)
	}
}

func TestNativeBackendInstallWingetDryRun(t *testing.T) {
	withHostOS(t, "windows")

	c := &catalog.Catalog{
		Platform: "windows",
		ToolSpecs: map[string][]catalog.ToolSpec{
			"gh": {
				{Manager: "winget", Package: "GitHub.cli"},
			},
		},
	}
	b := New(c)

	output, err := captureStdout(t, func() error {
		return b.Install([]string{"gh"}, true)
	})
	if err != nil {
		t.Fatalf("install dry-run: %v", err)
	}
	if !strings.Contains(output, "DRY RUN: would run: winget install --exact --id GitHub.cli --accept-source-agreements --accept-package-agreements") {
		t.Fatalf("expected winget dry-run command in output, got: %q", output)
	}
}

func TestNativeBackendInstallWingetStoreDryRun(t *testing.T) {
	withHostOS(t, "windows")

	c := &catalog.Catalog{
		Platform: "windows",
		ToolSpecs: map[string][]catalog.ToolSpec{
			"julia": {
				{Manager: "winget-store", Package: "9NJNWW8PVKMN", Source: "msstore"},
			},
		},
	}
	b := New(c)

	output, err := captureStdout(t, func() error {
		return b.Install([]string{"julia"}, true)
	})
	if err != nil {
		t.Fatalf("install dry-run: %v", err)
	}
	if !strings.Contains(output, "DRY RUN: would run: winget install --exact --id 9NJNWW8PVKMN --source msstore --accept-source-agreements --accept-package-agreements") {
		t.Fatalf("expected winget-store dry-run command in output, got: %q", output)
	}
}
