PYTHON ?= python3
VERILATOR ?= verilator
BUILD_DIR ?= build

PROFILE_RTL_SOURCES := rtl/arm9_profile_pkg.sv
CONDITION_RTL_SOURCES := rtl/arm9_condition_eval.sv
REGISTER_FILE_RTL_SOURCES := rtl/arm9_arch_pkg.sv rtl/arm9_banked_register_file.sv
STATUS_RTL_SOURCES := rtl/arm9_profile_pkg.sv rtl/arm9_arch_pkg.sv \
	rtl/arm9_psr_pkg.sv rtl/arm9_status_registers.sv
SHIFTER_RTL_SOURCES := rtl/arm9_isa_pkg.sv rtl/arm9_barrel_shifter.sv
DATA_ALU_RTL_SOURCES := rtl/arm9_isa_pkg.sv rtl/arm9_data_alu.sv
IMMEDIATE_RTL_SOURCES := rtl/arm9_immediate_expander.sv
DATA_DECODER_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_data_processing_decoder.sv
DATA_EXECUTE_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_condition_eval.sv rtl/arm9_barrel_shifter.sv \
	rtl/arm9_immediate_expander.sv rtl/arm9_data_alu.sv \
	rtl/arm9_data_processing_decoder.sv rtl/arm9_data_processing_execute.sv
PC_RTL_SOURCES := rtl/arm9_pc_addressing.sv
ARM9TDMI_TB := tb/unit/profile_arm9tdmi_tb.sv
ARM946ES_TB := tb/unit/profile_arm946es_tb.sv
CONDITION_TB := tb/unit/condition_eval_tb.sv
REGISTER_FILE_TB := tb/unit/banked_register_file_tb.sv
STATUS_TB := tb/unit/status_registers_tb.sv
SHIFTER_TB := tb/unit/barrel_shifter_tb.sv
DATA_ALU_TB := tb/unit/data_alu_tb.sv
IMMEDIATE_TB := tb/unit/immediate_expander_tb.sv
DATA_DECODER_TB := tb/unit/data_processing_decoder_tb.sv
DATA_EXECUTE_TB := tb/unit/data_processing_execute_tb.sv
PC_TB := tb/unit/pc_addressing_tb.sv

VERILATOR_COMMON := --Wall --assert --binary --timescale 1ns/1ps

.PHONY: all help toolchain spec lint compile test test-unit test-rtl-unit \
	test-condition test-register-file test-arm9tdmi test-arm946es test-timing \
	test-status-registers test-shifter test-data-alu test-immediate \
	test-data-decoder test-data-execute test-pc test-formal synth regression clean

all: test

help:
	@echo "Targets:"
	@echo "  toolchain       report required and optional tool versions"
	@echo "  spec            validate source/specification traceability"
	@echo "  lint            run Verilator lint for both profile tests"
	@echo "  compile         elaborate and compile both profile tests"
	@echo "  test            run specification and executable unit tests"
	@echo "  test-condition  exhaustively test all ARM condition/flag inputs"
	@echo "  test-register-file test all architectural register banks"
	@echo "  test-status-registers test CPSR/SPSR storage and profile masks"
	@echo "  test-shifter    exhaustively test ARM shift amounts and boundaries"
	@echo "  test-data-alu   exhaustively test ARM data-processing ALU classes"
	@echo "  test-immediate  exhaustively test ARM rotated-immediate encodings"
	@echo "  test-data-decoder exhaustively test ARM data-processing decode"
	@echo "  test-data-execute test integrated ARM data-processing execution"
	@echo "  test-pc         test ARM/Thumb PC read and write rules"
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
		--top-module profile_arm9tdmi_tb $(PROFILE_RTL_SOURCES) $(ARM9TDMI_TB)
	$(VERILATOR) --lint-only --Wall --assert --timescale 1ns/1ps \
		--top-module profile_arm946es_tb $(PROFILE_RTL_SOURCES) $(ARM946ES_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module condition_eval_tb $(CONDITION_RTL_SOURCES) $(CONDITION_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module banked_register_file_tb $(REGISTER_FILE_RTL_SOURCES) $(REGISTER_FILE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module status_registers_tb $(STATUS_RTL_SOURCES) $(STATUS_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module barrel_shifter_tb $(SHIFTER_RTL_SOURCES) $(SHIFTER_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module data_alu_tb $(DATA_ALU_RTL_SOURCES) $(DATA_ALU_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module immediate_expander_tb $(IMMEDIATE_RTL_SOURCES) $(IMMEDIATE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module data_processing_decoder_tb \
		$(DATA_DECODER_RTL_SOURCES) $(DATA_DECODER_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module data_processing_execute_tb \
		$(DATA_EXECUTE_RTL_SOURCES) $(DATA_EXECUTE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module pc_addressing_tb $(PC_RTL_SOURCES) $(PC_TB)

$(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb: $(PROFILE_RTL_SOURCES) $(ARM9TDMI_TB)
	@mkdir -p $(BUILD_DIR)/profile_arm9tdmi
	$(VERILATOR) $(VERILATOR_COMMON) --Mdir $(BUILD_DIR)/profile_arm9tdmi \
		--top-module profile_arm9tdmi_tb $(PROFILE_RTL_SOURCES) $(ARM9TDMI_TB)

$(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb: $(PROFILE_RTL_SOURCES) $(ARM946ES_TB)
	@mkdir -p $(BUILD_DIR)/profile_arm946es
	$(VERILATOR) $(VERILATOR_COMMON) --Mdir $(BUILD_DIR)/profile_arm946es \
		--top-module profile_arm946es_tb $(PROFILE_RTL_SOURCES) $(ARM946ES_TB)

$(BUILD_DIR)/condition_eval/Vcondition_eval_tb: $(CONDITION_RTL_SOURCES) $(CONDITION_TB)
	@mkdir -p $(BUILD_DIR)/condition_eval
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/condition_eval \
		--top-module condition_eval_tb $(CONDITION_RTL_SOURCES) $(CONDITION_TB)

$(BUILD_DIR)/banked_register_file/Vbanked_register_file_tb: \
	$(REGISTER_FILE_RTL_SOURCES) $(REGISTER_FILE_TB)
	@mkdir -p $(BUILD_DIR)/banked_register_file
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/banked_register_file \
		--top-module banked_register_file_tb $(REGISTER_FILE_RTL_SOURCES) $(REGISTER_FILE_TB)

$(BUILD_DIR)/status_registers/Vstatus_registers_tb: $(STATUS_RTL_SOURCES) $(STATUS_TB)
	@mkdir -p $(BUILD_DIR)/status_registers
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/status_registers \
		--top-module status_registers_tb $(STATUS_RTL_SOURCES) $(STATUS_TB)

$(BUILD_DIR)/barrel_shifter/Vbarrel_shifter_tb: $(SHIFTER_RTL_SOURCES) $(SHIFTER_TB)
	@mkdir -p $(BUILD_DIR)/barrel_shifter
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/barrel_shifter \
		--top-module barrel_shifter_tb $(SHIFTER_RTL_SOURCES) $(SHIFTER_TB)

$(BUILD_DIR)/data_alu/Vdata_alu_tb: $(DATA_ALU_RTL_SOURCES) $(DATA_ALU_TB)
	@mkdir -p $(BUILD_DIR)/data_alu
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/data_alu \
		--top-module data_alu_tb $(DATA_ALU_RTL_SOURCES) $(DATA_ALU_TB)

$(BUILD_DIR)/immediate_expander/Vimmediate_expander_tb: \
	$(IMMEDIATE_RTL_SOURCES) $(IMMEDIATE_TB)
	@mkdir -p $(BUILD_DIR)/immediate_expander
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/immediate_expander \
		--top-module immediate_expander_tb $(IMMEDIATE_RTL_SOURCES) $(IMMEDIATE_TB)

$(BUILD_DIR)/data_processing_decoder/Vdata_processing_decoder_tb: \
	$(DATA_DECODER_RTL_SOURCES) $(DATA_DECODER_TB)
	@mkdir -p $(BUILD_DIR)/data_processing_decoder
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/data_processing_decoder \
		--top-module data_processing_decoder_tb \
		$(DATA_DECODER_RTL_SOURCES) $(DATA_DECODER_TB)

$(BUILD_DIR)/data_processing_execute/Vdata_processing_execute_tb: \
	$(DATA_EXECUTE_RTL_SOURCES) $(DATA_EXECUTE_TB)
	@mkdir -p $(BUILD_DIR)/data_processing_execute
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/data_processing_execute \
		--top-module data_processing_execute_tb \
		$(DATA_EXECUTE_RTL_SOURCES) $(DATA_EXECUTE_TB)

$(BUILD_DIR)/pc_addressing/Vpc_addressing_tb: $(PC_RTL_SOURCES) $(PC_TB)
	@mkdir -p $(BUILD_DIR)/pc_addressing
	$(VERILATOR) $(VERILATOR_COMMON) --timing --Mdir $(BUILD_DIR)/pc_addressing \
		--top-module pc_addressing_tb $(PC_RTL_SOURCES) $(PC_TB)

compile: $(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb \
	$(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb \
	$(BUILD_DIR)/condition_eval/Vcondition_eval_tb \
	$(BUILD_DIR)/banked_register_file/Vbanked_register_file_tb \
	$(BUILD_DIR)/status_registers/Vstatus_registers_tb \
	$(BUILD_DIR)/barrel_shifter/Vbarrel_shifter_tb \
	$(BUILD_DIR)/data_alu/Vdata_alu_tb \
	$(BUILD_DIR)/immediate_expander/Vimmediate_expander_tb \
	$(BUILD_DIR)/data_processing_decoder/Vdata_processing_decoder_tb \
	$(BUILD_DIR)/data_processing_execute/Vdata_processing_execute_tb \
	$(BUILD_DIR)/pc_addressing/Vpc_addressing_tb

test-unit:
	$(PYTHON) -m unittest discover -s tests -p 'test_*.py' -v

test-arm9tdmi: $(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb
	$(BUILD_DIR)/profile_arm9tdmi/Vprofile_arm9tdmi_tb

test-arm946es: $(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb
	$(BUILD_DIR)/profile_arm946es/Vprofile_arm946es_tb

test-condition: $(BUILD_DIR)/condition_eval/Vcondition_eval_tb
	$(BUILD_DIR)/condition_eval/Vcondition_eval_tb

test-register-file: $(BUILD_DIR)/banked_register_file/Vbanked_register_file_tb
	$(BUILD_DIR)/banked_register_file/Vbanked_register_file_tb

test-status-registers: $(BUILD_DIR)/status_registers/Vstatus_registers_tb
	$(BUILD_DIR)/status_registers/Vstatus_registers_tb

test-shifter: $(BUILD_DIR)/barrel_shifter/Vbarrel_shifter_tb
	$(BUILD_DIR)/barrel_shifter/Vbarrel_shifter_tb

test-data-alu: $(BUILD_DIR)/data_alu/Vdata_alu_tb
	$(BUILD_DIR)/data_alu/Vdata_alu_tb

test-immediate: $(BUILD_DIR)/immediate_expander/Vimmediate_expander_tb
	$(BUILD_DIR)/immediate_expander/Vimmediate_expander_tb

test-data-decoder: $(BUILD_DIR)/data_processing_decoder/Vdata_processing_decoder_tb
	$(BUILD_DIR)/data_processing_decoder/Vdata_processing_decoder_tb

test-data-execute: $(BUILD_DIR)/data_processing_execute/Vdata_processing_execute_tb
	$(BUILD_DIR)/data_processing_execute/Vdata_processing_execute_tb

test-pc: $(BUILD_DIR)/pc_addressing/Vpc_addressing_tb
	$(BUILD_DIR)/pc_addressing/Vpc_addressing_tb

test-rtl-unit: test-condition test-register-file test-status-registers test-shifter \
	test-data-alu test-immediate test-data-decoder test-data-execute test-pc

test-timing:
	$(PYTHON) -m unittest discover -s tests/timing -p 'test_*.py' -v

test: spec test-unit test-rtl-unit test-arm9tdmi test-arm946es

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
