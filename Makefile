SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

.PHONY: build test test-updates all

BUNDLES := full cloud services ai

all: build test

build:
	@bash -lc 'set -euo pipefail; \
		test -f .bash/install.sh; \
		test -f .bash/uninstall.sh; \
		test -f .tools/install.sh; \
		test -f .tools/uninstall.sh; \
		test -f .tools/update.sh; \
		bash -n update.sh; \
		bash -n list.sh; \
		bash -n uninstall.sh; \
		test -f .tools/list.sh; \
		test -d helm; \
		for f in .bash/*.sh; do echo "  - $$f"; bash -n "$$f"; done; \
		for f in .tools/*.sh; do echo "  - $$f"; bash -n "$$f"; done; \
		for f in */install.sh */uninstall.sh */update.sh */bash.sh; do if [[ -f "$$f" ]]; then echo "  - $$f"; bash -n "$$f"; fi; done; \
		for f in helm/*.sh; do echo "  - $$f"; bash -n "$$f"; done; \
		tmpdir=$$(mktemp -d); \
		chart_tmp="$$tmpdir/chart.yaml"; \
		printf "%s\n" \
			"apiVersion: v2" \
			"name: demo" \
			"description: temp fixture for CI validation" \
			"version: 0.1.0" \
			"appVersion: old" > "$$chart_tmp"; \
		expected_sha=$$(git rev-parse HEAD); \
		CHART_FILE="$$chart_tmp" bash ./helm/set-version.sh; \
		echo "Resulting chart fixture:"; \
		cat "$$chart_tmp"; \
		grep -Eq "^version: [0-9]{4}[.][0-9]{2}[.][0-9]{2}[.][0-9]{4}$$" "$$chart_tmp"; \
		grep -Eq "^appVersion: $${expected_sha}$$" "$$chart_tmp"; \
		rm -rf "$$tmpdir"'

test-updates:
	@bash ./.tools/update-test.sh

test: test-updates
	@bash -lc 'set -euo pipefail; \
		for bundle in $(BUNDLES); do echo "Testing install bundle: $$bundle"; bash ./.tools/install.sh "$$bundle" --dry-run; done; \
		for bundle in $(BUNDLES); do echo "Testing uninstall bundle: $$bundle"; bash ./.tools/uninstall.sh "$$bundle" --dry-run; done; \
		echo "Testing Julia alias and opt-in placement"; \
		source ./.tools/common.sh; \
		[[ "$$(canonical_tool_name juliaup)" == julia ]]; \
		[[ "$$(resolve_target_tools julia juliaup)" == julia ]]; \
		[[ " $${FULL_BUNDLE[*]} " != *" julia "* && " $${AI_BUNDLE[*]} " != *" julia "* && " $${CLOUD_BUNDLE[*]} " != *" julia "* && " $${SERVICES_BUNDLE[*]} " != *" julia "* ]]; \
		julia_uninstall_output=$$(TOOLS_UNINSTALL_MODULE_INTERNAL=1 bash ./.tools/uninstall.sh julia --dry-run); \
		[[ "$$julia_uninstall_output" == *"left intact"* ]]; \
		echo "Testing Julia module dry runs"; \
		bash ./.tools/install.sh julia --dry-run; \
		bash ./.tools/install.sh juliaup --dry-run; \
		bash ./.tools/uninstall.sh julia --dry-run; \
		bash ./.tools/uninstall.sh juliaup --dry-run; \
		echo "Testing Julia Store winget source"; \
		source ./.tools/windows.sh; \
		winget_calls=(); \
		winget() { winget_calls+=("$$*"); [[ "$$1" != list ]]; }; \
		install_winget_msstore_if_missing "9NJNWW8PVKMN" "julia-test-missing"; \
		[[ $${#winget_calls[@]} -eq 2 ]]; \
		[[ "$${winget_calls[1]}" == *"--source msstore"* ]]; \
		echo "Testing R aliases and bundle order"; \
		source ./.tools/common.sh; \
		[[ "$$(canonical_tool_name R)" == r ]]; \
		[[ "$$(canonical_tool_name r-lang)" == r ]]; \
		assert_python_before_r() { local items=("$$@"); local python_index=-1; local r_index=-1; local index; for index in "$${!items[@]}"; do case "$${items[$$index]}" in python3) python_index=$$index ;; r) r_index=$$index ;; esac; done; [[ $$python_index -ge 0 && $$python_index -lt $$r_index ]]; }; \
		assert_python_before_r "$${FULL_BUNDLE[@]}"; \
		assert_python_before_r "$${AI_BUNDLE[@]}"; \
		[[ " $${CLOUD_BUNDLE[*]} " != *" r "* && " $${SERVICES_BUNDLE[*]} " != *" r "* ]]; \
		echo "Testing R module dry runs"; \
		for tool in r R r-lang; do bash ./.tools/install.sh "$$tool" --dry-run; bash ./.tools/uninstall.sh "$$tool" --dry-run; done; \
		echo "Testing Scala alias and bundle order"; \
		source ./.tools/common.sh; \
		[[ "$$(canonical_tool_name scala-cli)" == scala ]]; \
		assert_java_before_scala() { local items=("$$@"); local java_index=-1; local scala_index=-1; local index; for index in "$${!items[@]}"; do case "$${items[$$index]}" in java) java_index=$$index ;; scala) scala_index=$$index ;; esac; done; [[ $$java_index -ge 0 && $$java_index -lt $$scala_index ]]; }; \
		assert_java_before_scala "$${FULL_BUNDLE[@]}"; \
		assert_java_before_scala "$${AI_BUNDLE[@]}"; \
		[[ " $${CLOUD_BUNDLE[*]} " != *" scala "* && " $${SERVICES_BUNDLE[*]} " != *" scala "* ]]; \
		echo "Testing Scala module dry runs"; \
		bash ./.tools/install.sh scala --dry-run; \
		bash ./.tools/install.sh scala-cli --dry-run; \
		bash ./.tools/uninstall.sh scala --dry-run; \
		bash ./.tools/uninstall.sh scala-cli --dry-run; \
		echo "Testing Rust/C++ aliases and bundle order"; \
		source ./.tools/common.sh; \
		[[ "$$(canonical_tool_name rustup)" == rust ]]; \
		[[ "$$(canonical_tool_name c++)" == cpp ]]; \
		assert_cpp_before_rust() { local items=("$$@"); local cpp_index=-1; local rust_index=-1; local index; for index in "$${!items[@]}"; do case "$${items[$$index]}" in cpp) cpp_index=$$index ;; rust) rust_index=$$index ;; esac; done; [[ $$cpp_index -ge 0 && $$cpp_index -lt $$rust_index ]]; }; \
		assert_cpp_before_rust "$${FULL_BUNDLE[@]}"; \
		assert_cpp_before_rust "$${AI_BUNDLE[@]}"; \
		[[ " $${CLOUD_BUNDLE[*]} " != *" cpp "* && " $${CLOUD_BUNDLE[*]} " != *" rust "* ]]; \
		[[ " $${SERVICES_BUNDLE[*]} " != *" cpp "* && " $${SERVICES_BUNDLE[*]} " != *" rust "* ]]; \
		echo "Testing Rust uninstall preservation"; \
		rust_uninstall_output=$$(TOOLS_UNINSTALL_MODULE_INTERNAL=1 bash ./.tools/uninstall.sh rust --dry-run); \
		[[ "$$rust_uninstall_output" == *"left intact"* ]]; \
		echo "Testing C++ macOS CLT request"; \
		source ./.tools/macos.sh; \
		xcode_calls=(); \
		xcode-select() { xcode_calls+=("$$*"); [[ "$$*" != -p ]]; }; \
		install_mac cpp; \
		[[ "$${xcode_calls[*]}" == "-p --install" ]]; \
		echo "Testing C++ Windows workload arguments"; \
		source ./.tools/windows.sh; \
		winget_calls=(); \
		winget() { winget_calls+=("$$*"); [[ "$$1" != list ]]; }; \
		install_winget_with_override_if_missing "Microsoft.VisualStudio.2022.BuildTools" "--quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows11SDK.26100"; \
		[[ $${#winget_calls[@]} -eq 2 ]]; \
		[[ "$${winget_calls[1]}" == *"--override --quiet --wait --norestart --add Microsoft.VisualStudio.Workload.VCTools"* ]]; \
		echo "Testing Rust/C++ module dry runs"; \
		for tool in rust rustup cpp c++; do bash ./.tools/install.sh "$$tool" --dry-run; bash ./.tools/uninstall.sh "$$tool" --dry-run; done; \
		echo "Testing Java aliases"; \
		bash ./.tools/install.sh java --dry-run; \
		bash ./.tools/install.sh jdk --dry-run; \
		bash ./.tools/uninstall.sh java --dry-run; \
		bash ./.tools/uninstall.sh jdk --dry-run; \
		echo "Testing Java macOS uninstall mapping"; \
		TOOL_SHED_OS_OVERRIDE=Darwin TOOLS_UNINSTALL_MODULE_INTERNAL=1 bash ./.tools/uninstall.sh java --dry-run'