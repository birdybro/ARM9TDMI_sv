PYTHON ?= python3
VERILATOR ?= verilator
BUILD_DIR ?= build

RTL_SOURCES := rtl/arm9_profile_pkg.sv
ARM9TDMI_TB := tb/unit/profile_arm9tdmi_tb.sv
ARM946ES_TB := tb/unit/profile_arm946es_tb.sv

VERILATOR_COMMON := --Wall --assert --binary --timescale 1ns/1ps

.PHONY: all help toolchain spec lint compile test test-unit test-arm9tdmi \
	test-arm946es test-timing test-formal synth regression clean

all: test

help:
	@echo "Targets:"
	@echo "  toolchain       report required and optional tool versions"
	@echo "  spec            validate source/specification traceability"
	@echo "  lint            run Verilator lint for both profile tests"
	@echo "  compile         elaborate and compile both profile tests"
	@echo "  test            run specification and executable unit tests"
	@echo "  test-arm9tdmi   run ARM9TDMI-profile tests"
	@echo "  test-arm946es   run ARM946E-S-profile tests"
	@echo "  test-timing     validate timing-oracle specification tests"
	@echo "  test-formal     run formal flow (requires SymbiYosys)"
	@echo "  synth           run synthesis flow (requires Yosys)"
	@echo "  regression      run current full non-formal regression"

toolchain:
	$(PYTHON) tools/check_toolchain.py

spec:
	$(PYTHON) tools/validate_spec.py

lint: spec
	@command -v $(VERILATOR) >/dev/null || { echo "ERROR: Verilator is required" >&2; exit 1; }
	$(VERILATOR) --lint-only --Wall --assert --timescale 1ns/1ps \
		--top-module profile_arm9tdmi_tb $(RTL_SOURCES) $(ARM9TDMI_TB)
	$(VERILATOR) --lint-only --Wall --assert --timescale 1ns/1ps \
		--top-module profile_arm946es_tb $(RTL_SOURCES) $(ARM946ES_TB)

$(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb: $(RTL_SOURCES) $(ARM9TDMI_TB)
	@mkdir -p $(BUILD_DIR)/profile_arm9tdmi
	$(VERILATOR) $(VERILATOR_COMMON) --Mdir $(BUILD_DIR)/profile_arm9tdmi \
		--top-module profile_arm9tdmi_tb $(RTL_SOURCES) $(ARM9TDMI_TB)

$(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb: $(RTL_SOURCES) $(ARM946ES_TB)
	@mkdir -p $(BUILD_DIR)/profile_arm946es
	$(VERILATOR) $(VERILATOR_COMMON) --Mdir $(BUILD_DIR)/profile_arm946es \
		--top-module profile_arm946es_tb $(RTL_SOURCES) $(ARM946ES_TB)

compile: $(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb \
	$(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb

test-unit:
	$(PYTHON) -m unittest discover -s tests -p 'test_*.py' -v

test-arm9tdmi: $(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb
	$(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb

test-arm946es: $(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb
	$(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb

test-timing:
	$(PYTHON) -m unittest discover -s tests/timing -p 'test_*.py' -v

test: spec test-unit test-arm9tdmi test-arm946es

test-formal:
	@command -v sby >/dev/null || { echo "ERROR: SymbiYosys (sby) is required" >&2; exit 1; }
	@test -f formal/arm9.sby || { echo "ERROR: formal harness is not implemented yet" >&2; exit 1; }
	sby -f formal/arm9.sby

synth:
	@command -v yosys >/dev/null || { echo "ERROR: Yosys is required" >&2; exit 1; }
	@test -f scripts/synth.tcl || { echo "ERROR: synthesis script is not implemented yet" >&2; exit 1; }
	yosys -c scripts/synth.tcl

regression: lint compile test

clean:
	rm -rf $(BUILD_DIR)
