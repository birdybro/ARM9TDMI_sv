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
ARM_BRANCH_RTL_SOURCES := rtl/arm9_profile_pkg.sv rtl/arm9_isa_pkg.sv \
	rtl/arm9_condition_eval.sv rtl/arm9_arm_branch_execute.sv
MULTIPLIER_TIMING_RTL_SOURCES := rtl/arm9_profile_pkg.sv rtl/arm9_isa_pkg.sv \
	rtl/arm9_multiplier_timing.sv
MULTIPLY_DECODER_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_multiply_decoder.sv
COMMON_MULTIPLY_ALU_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_isa_pkg.sv rtl/arm9_common_multiply_alu.sv
COMMON_MULTIPLY_EXECUTE_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_isa_pkg.sv rtl/arm9_condition_eval.sv \
	rtl/arm9_multiply_decoder.sv rtl/arm9_common_multiply_alu.sv \
	rtl/arm9_common_multiply_execute.sv
DSP_MULTIPLY_DECODER_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_isa_pkg.sv rtl/arm9_dsp_multiply_decoder.sv
DSP_MULTIPLY_ALU_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9e_dsp_multiply_alu.sv
DSP_MULTIPLY_EXECUTE_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_isa_pkg.sv rtl/arm9_condition_eval.sv \
	rtl/arm9_dsp_multiply_decoder.sv rtl/arm9e_dsp_multiply_alu.sv \
	rtl/arm9_dsp_multiply_execute.sv
CLZ_EXECUTE_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_condition_eval.sv rtl/arm9_clz_execute.sv
SATURATING_DECODER_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_isa_pkg.sv rtl/arm9_saturating_decoder.sv
SATURATING_ALU_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9e_saturating_alu.sv
SATURATING_EXECUTE_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_isa_pkg.sv rtl/arm9_condition_eval.sv \
	rtl/arm9_saturating_decoder.sv rtl/arm9e_saturating_alu.sv \
	rtl/arm9_saturating_execute.sv
ADDRESS_MODE2_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_barrel_shifter.sv rtl/arm9_address_mode2.sv
SINGLE_TRANSFER_PREPARE_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_condition_eval.sv rtl/arm9_barrel_shifter.sv \
	rtl/arm9_address_mode2.sv rtl/arm9_single_transfer_prepare.sv
STORE_DATA_SELECT_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_store_data_select.sv
LOAD_DATA_ALIGN_RTL_SOURCES := rtl/arm9_load_data_align.sv
SINGLE_LOAD_COMPLETE_RTL_SOURCES := rtl/arm9_profile_pkg.sv \
	rtl/arm9_single_load_complete.sv
SINGLE_STORE_COMPLETE_RTL_SOURCES := rtl/arm9_single_store_complete.sv
ADDRESS_MODE3_RTL_SOURCES := rtl/arm9_isa_pkg.sv rtl/arm9_address_mode3.sv
MISC_TRANSFER_PREPARE_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_condition_eval.sv rtl/arm9_address_mode3.sv \
	rtl/arm9_misc_transfer_prepare.sv
MISC_LOAD_DATA_FORMAT_RTL_SOURCES := rtl/arm9_isa_pkg.sv \
	rtl/arm9_misc_load_data_format.sv
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
ARM_BRANCH_TB := tb/unit/arm_branch_execute_tb.sv
MULTIPLIER_TIMING_TB := tb/unit/multiplier_timing_tb.sv
MULTIPLY_DECODER_TB := tb/unit/multiply_decoder_tb.sv
COMMON_MULTIPLY_ALU_TB := tb/unit/common_multiply_alu_tb.sv
COMMON_MULTIPLY_EXECUTE_TB := tb/unit/common_multiply_execute_tb.sv
DSP_MULTIPLY_DECODER_TB := tb/unit/dsp_multiply_decoder_tb.sv
DSP_MULTIPLY_ALU_TB := tb/unit/dsp_multiply_alu_tb.sv
DSP_MULTIPLY_EXECUTE_TB := tb/unit/dsp_multiply_execute_tb.sv
CLZ_EXECUTE_TB := tb/unit/clz_execute_tb.sv
SATURATING_DECODER_TB := tb/unit/saturating_decoder_tb.sv
SATURATING_ALU_TB := tb/unit/saturating_alu_tb.sv
SATURATING_EXECUTE_TB := tb/unit/saturating_execute_tb.sv
ADDRESS_MODE2_TB := tb/unit/address_mode2_tb.sv
SINGLE_TRANSFER_PREPARE_TB := tb/unit/single_transfer_prepare_tb.sv
STORE_DATA_SELECT_TB := tb/unit/store_data_select_tb.sv
LOAD_DATA_ALIGN_TB := tb/unit/load_data_align_tb.sv
SINGLE_LOAD_COMPLETE_TB := tb/unit/single_load_complete_tb.sv
SINGLE_STORE_COMPLETE_TB := tb/unit/single_store_complete_tb.sv
ADDRESS_MODE3_TB := tb/unit/address_mode3_tb.sv
MISC_TRANSFER_PREPARE_TB := tb/unit/misc_transfer_prepare_tb.sv
MISC_LOAD_DATA_FORMAT_TB := tb/unit/misc_load_data_format_tb.sv

VERILATOR_COMMON := --Wall --assert --binary --timescale 1ns/1ps

.PHONY: all help toolchain spec lint compile test test-unit test-rtl-unit \
	test-condition test-register-file test-arm9tdmi test-arm946es test-timing \
	test-status-registers test-shifter test-data-alu test-immediate \
	test-data-decoder test-data-execute test-pc test-arm-branch \
	test-multiplier-timing test-multiply-decoder test-common-multiply-alu \
	test-common-multiply-execute test-dsp-multiply-decoder \
	test-dsp-multiply-alu test-dsp-multiply-execute test-clz-execute \
	test-saturating-decoder test-saturating-alu test-saturating-execute \
	test-address-mode2 test-single-transfer-prepare test-store-data-select \
	test-load-data-align test-single-load-complete test-single-store-complete \
	test-address-mode3 test-misc-transfer-prepare test-misc-load-data-format \
	test-formal synth \
	regression clean

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
	@echo "  test-arm-branch test profile-specific ARM B/BL/BX/BLX behavior"
	@echo "  test-multiplier-timing test profile-specific multiply latency"
	@echo "  test-multiply-decoder test common ARM multiply decode space"
	@echo "  test-common-multiply-alu test common ARM multiply arithmetic"
	@echo "  test-common-multiply-execute test integrated common ARM multiply"
	@echo "  test-dsp-multiply-decoder test ARMv5TE DSP multiply decode"
	@echo "  test-dsp-multiply-alu test ARMv5TE DSP multiply arithmetic"
	@echo "  test-dsp-multiply-execute test integrated ARMv5TE DSP multiply"
	@echo "  test-clz-execute test profile-specific ARM CLZ execution"
	@echo "  test-saturating-decoder test ARMv5TE saturating decode"
	@echo "  test-saturating-alu test ARMv5TE saturating arithmetic"
	@echo "  test-saturating-execute test integrated saturating execution"
	@echo "  test-address-mode2 test ARM word/byte address generation"
	@echo "  test-single-transfer-prepare test conditioned LDR/STR request intent"
	@echo "  test-store-data-select test profile-specific STR store values"
	@echo "  test-load-data-align test pre-ARMv6 load alignment behavior"
	@echo "  test-single-load-complete test LDR completion, PC, and abort intent"
	@echo "  test-single-store-complete test STR completion and abort intent"
	@echo "  test-address-mode3 test common ARM miscellaneous transfer addresses"
	@echo "  test-misc-transfer-prepare test common halfword/signed request intent"
	@echo "  test-misc-load-data-format test LDRH/LDRSB/LDRSH extension"
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
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module arm_branch_execute_tb \
		$(ARM_BRANCH_RTL_SOURCES) $(ARM_BRANCH_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module multiplier_timing_tb \
		$(MULTIPLIER_TIMING_RTL_SOURCES) $(MULTIPLIER_TIMING_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module multiply_decoder_tb \
		$(MULTIPLY_DECODER_RTL_SOURCES) $(MULTIPLY_DECODER_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module common_multiply_alu_tb \
		$(COMMON_MULTIPLY_ALU_RTL_SOURCES) $(COMMON_MULTIPLY_ALU_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module common_multiply_execute_tb \
		$(COMMON_MULTIPLY_EXECUTE_RTL_SOURCES) $(COMMON_MULTIPLY_EXECUTE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module dsp_multiply_decoder_tb \
		$(DSP_MULTIPLY_DECODER_RTL_SOURCES) $(DSP_MULTIPLY_DECODER_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module dsp_multiply_alu_tb \
		$(DSP_MULTIPLY_ALU_RTL_SOURCES) $(DSP_MULTIPLY_ALU_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module dsp_multiply_execute_tb \
		$(DSP_MULTIPLY_EXECUTE_RTL_SOURCES) $(DSP_MULTIPLY_EXECUTE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module clz_execute_tb \
		$(CLZ_EXECUTE_RTL_SOURCES) $(CLZ_EXECUTE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module saturating_decoder_tb \
		$(SATURATING_DECODER_RTL_SOURCES) $(SATURATING_DECODER_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module saturating_alu_tb \
		$(SATURATING_ALU_RTL_SOURCES) $(SATURATING_ALU_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module saturating_execute_tb \
		$(SATURATING_EXECUTE_RTL_SOURCES) $(SATURATING_EXECUTE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module address_mode2_tb \
		$(ADDRESS_MODE2_RTL_SOURCES) $(ADDRESS_MODE2_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module single_transfer_prepare_tb \
		$(SINGLE_TRANSFER_PREPARE_RTL_SOURCES) $(SINGLE_TRANSFER_PREPARE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module store_data_select_tb \
		$(STORE_DATA_SELECT_RTL_SOURCES) $(STORE_DATA_SELECT_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module load_data_align_tb \
		$(LOAD_DATA_ALIGN_RTL_SOURCES) $(LOAD_DATA_ALIGN_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module single_load_complete_tb \
		$(SINGLE_LOAD_COMPLETE_RTL_SOURCES) $(SINGLE_LOAD_COMPLETE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module single_store_complete_tb \
		$(SINGLE_STORE_COMPLETE_RTL_SOURCES) $(SINGLE_STORE_COMPLETE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module address_mode3_tb \
		$(ADDRESS_MODE3_RTL_SOURCES) $(ADDRESS_MODE3_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module misc_transfer_prepare_tb \
		$(MISC_TRANSFER_PREPARE_RTL_SOURCES) $(MISC_TRANSFER_PREPARE_TB)
	$(VERILATOR) --lint-only --Wall --assert --timing --timescale 1ns/1ps \
		--top-module misc_load_data_format_tb \
		$(MISC_LOAD_DATA_FORMAT_RTL_SOURCES) $(MISC_LOAD_DATA_FORMAT_TB)

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

$(BUILD_DIR)/arm_branch_execute/Varm_branch_execute_tb: \
	$(ARM_BRANCH_RTL_SOURCES) $(ARM_BRANCH_TB)
	@mkdir -p $(BUILD_DIR)/arm_branch_execute
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/arm_branch_execute \
		--top-module arm_branch_execute_tb \
		$(ARM_BRANCH_RTL_SOURCES) $(ARM_BRANCH_TB)

$(BUILD_DIR)/multiplier_timing/Vmultiplier_timing_tb: \
	$(MULTIPLIER_TIMING_RTL_SOURCES) $(MULTIPLIER_TIMING_TB)
	@mkdir -p $(BUILD_DIR)/multiplier_timing
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/multiplier_timing \
		--top-module multiplier_timing_tb \
		$(MULTIPLIER_TIMING_RTL_SOURCES) $(MULTIPLIER_TIMING_TB)

$(BUILD_DIR)/multiply_decoder/Vmultiply_decoder_tb: \
	$(MULTIPLY_DECODER_RTL_SOURCES) $(MULTIPLY_DECODER_TB)
	@mkdir -p $(BUILD_DIR)/multiply_decoder
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/multiply_decoder \
		--top-module multiply_decoder_tb \
		$(MULTIPLY_DECODER_RTL_SOURCES) $(MULTIPLY_DECODER_TB)

$(BUILD_DIR)/common_multiply_alu/Vcommon_multiply_alu_tb: \
	$(COMMON_MULTIPLY_ALU_RTL_SOURCES) $(COMMON_MULTIPLY_ALU_TB)
	@mkdir -p $(BUILD_DIR)/common_multiply_alu
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/common_multiply_alu \
		--top-module common_multiply_alu_tb \
		$(COMMON_MULTIPLY_ALU_RTL_SOURCES) $(COMMON_MULTIPLY_ALU_TB)

$(BUILD_DIR)/common_multiply_execute/Vcommon_multiply_execute_tb: \
	$(COMMON_MULTIPLY_EXECUTE_RTL_SOURCES) $(COMMON_MULTIPLY_EXECUTE_TB)
	@mkdir -p $(BUILD_DIR)/common_multiply_execute
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/common_multiply_execute \
		--top-module common_multiply_execute_tb \
		$(COMMON_MULTIPLY_EXECUTE_RTL_SOURCES) $(COMMON_MULTIPLY_EXECUTE_TB)

$(BUILD_DIR)/dsp_multiply_decoder/Vdsp_multiply_decoder_tb: \
	$(DSP_MULTIPLY_DECODER_RTL_SOURCES) $(DSP_MULTIPLY_DECODER_TB)
	@mkdir -p $(BUILD_DIR)/dsp_multiply_decoder
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/dsp_multiply_decoder \
		--top-module dsp_multiply_decoder_tb \
		$(DSP_MULTIPLY_DECODER_RTL_SOURCES) $(DSP_MULTIPLY_DECODER_TB)

$(BUILD_DIR)/dsp_multiply_alu/Vdsp_multiply_alu_tb: \
	$(DSP_MULTIPLY_ALU_RTL_SOURCES) $(DSP_MULTIPLY_ALU_TB)
	@mkdir -p $(BUILD_DIR)/dsp_multiply_alu
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/dsp_multiply_alu \
		--top-module dsp_multiply_alu_tb \
		$(DSP_MULTIPLY_ALU_RTL_SOURCES) $(DSP_MULTIPLY_ALU_TB)

$(BUILD_DIR)/dsp_multiply_execute/Vdsp_multiply_execute_tb: \
	$(DSP_MULTIPLY_EXECUTE_RTL_SOURCES) $(DSP_MULTIPLY_EXECUTE_TB)
	@mkdir -p $(BUILD_DIR)/dsp_multiply_execute
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/dsp_multiply_execute \
		--top-module dsp_multiply_execute_tb \
		$(DSP_MULTIPLY_EXECUTE_RTL_SOURCES) $(DSP_MULTIPLY_EXECUTE_TB)

$(BUILD_DIR)/clz_execute/Vclz_execute_tb: \
	$(CLZ_EXECUTE_RTL_SOURCES) $(CLZ_EXECUTE_TB)
	@mkdir -p $(BUILD_DIR)/clz_execute
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/clz_execute \
		--top-module clz_execute_tb \
		$(CLZ_EXECUTE_RTL_SOURCES) $(CLZ_EXECUTE_TB)

$(BUILD_DIR)/saturating_decoder/Vsaturating_decoder_tb: \
	$(SATURATING_DECODER_RTL_SOURCES) $(SATURATING_DECODER_TB)
	@mkdir -p $(BUILD_DIR)/saturating_decoder
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/saturating_decoder \
		--top-module saturating_decoder_tb \
		$(SATURATING_DECODER_RTL_SOURCES) $(SATURATING_DECODER_TB)

$(BUILD_DIR)/saturating_alu/Vsaturating_alu_tb: \
	$(SATURATING_ALU_RTL_SOURCES) $(SATURATING_ALU_TB)
	@mkdir -p $(BUILD_DIR)/saturating_alu
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/saturating_alu \
		--top-module saturating_alu_tb \
		$(SATURATING_ALU_RTL_SOURCES) $(SATURATING_ALU_TB)

$(BUILD_DIR)/saturating_execute/Vsaturating_execute_tb: \
	$(SATURATING_EXECUTE_RTL_SOURCES) $(SATURATING_EXECUTE_TB)
	@mkdir -p $(BUILD_DIR)/saturating_execute
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/saturating_execute \
		--top-module saturating_execute_tb \
		$(SATURATING_EXECUTE_RTL_SOURCES) $(SATURATING_EXECUTE_TB)

$(BUILD_DIR)/address_mode2/Vaddress_mode2_tb: \
	$(ADDRESS_MODE2_RTL_SOURCES) $(ADDRESS_MODE2_TB)
	@mkdir -p $(BUILD_DIR)/address_mode2
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/address_mode2 \
		--top-module address_mode2_tb \
		$(ADDRESS_MODE2_RTL_SOURCES) $(ADDRESS_MODE2_TB)

$(BUILD_DIR)/single_transfer_prepare/Vsingle_transfer_prepare_tb: \
	$(SINGLE_TRANSFER_PREPARE_RTL_SOURCES) $(SINGLE_TRANSFER_PREPARE_TB)
	@mkdir -p $(BUILD_DIR)/single_transfer_prepare
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/single_transfer_prepare \
		--top-module single_transfer_prepare_tb \
		$(SINGLE_TRANSFER_PREPARE_RTL_SOURCES) $(SINGLE_TRANSFER_PREPARE_TB)

$(BUILD_DIR)/store_data_select/Vstore_data_select_tb: \
	$(STORE_DATA_SELECT_RTL_SOURCES) $(STORE_DATA_SELECT_TB)
	@mkdir -p $(BUILD_DIR)/store_data_select
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/store_data_select \
		--top-module store_data_select_tb \
		$(STORE_DATA_SELECT_RTL_SOURCES) $(STORE_DATA_SELECT_TB)

$(BUILD_DIR)/load_data_align/Vload_data_align_tb: \
	$(LOAD_DATA_ALIGN_RTL_SOURCES) $(LOAD_DATA_ALIGN_TB)
	@mkdir -p $(BUILD_DIR)/load_data_align
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/load_data_align \
		--top-module load_data_align_tb \
		$(LOAD_DATA_ALIGN_RTL_SOURCES) $(LOAD_DATA_ALIGN_TB)

$(BUILD_DIR)/single_load_complete/Vsingle_load_complete_tb: \
	$(SINGLE_LOAD_COMPLETE_RTL_SOURCES) $(SINGLE_LOAD_COMPLETE_TB)
	@mkdir -p $(BUILD_DIR)/single_load_complete
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/single_load_complete \
		--top-module single_load_complete_tb \
		$(SINGLE_LOAD_COMPLETE_RTL_SOURCES) $(SINGLE_LOAD_COMPLETE_TB)

$(BUILD_DIR)/single_store_complete/Vsingle_store_complete_tb: \
	$(SINGLE_STORE_COMPLETE_RTL_SOURCES) $(SINGLE_STORE_COMPLETE_TB)
	@mkdir -p $(BUILD_DIR)/single_store_complete
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/single_store_complete \
		--top-module single_store_complete_tb \
		$(SINGLE_STORE_COMPLETE_RTL_SOURCES) $(SINGLE_STORE_COMPLETE_TB)

$(BUILD_DIR)/address_mode3/Vaddress_mode3_tb: \
	$(ADDRESS_MODE3_RTL_SOURCES) $(ADDRESS_MODE3_TB)
	@mkdir -p $(BUILD_DIR)/address_mode3
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/address_mode3 \
		--top-module address_mode3_tb \
		$(ADDRESS_MODE3_RTL_SOURCES) $(ADDRESS_MODE3_TB)

$(BUILD_DIR)/misc_transfer_prepare/Vmisc_transfer_prepare_tb: \
	$(MISC_TRANSFER_PREPARE_RTL_SOURCES) $(MISC_TRANSFER_PREPARE_TB)
	@mkdir -p $(BUILD_DIR)/misc_transfer_prepare
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/misc_transfer_prepare \
		--top-module misc_transfer_prepare_tb \
		$(MISC_TRANSFER_PREPARE_RTL_SOURCES) $(MISC_TRANSFER_PREPARE_TB)

$(BUILD_DIR)/misc_load_data_format/Vmisc_load_data_format_tb: \
	$(MISC_LOAD_DATA_FORMAT_RTL_SOURCES) $(MISC_LOAD_DATA_FORMAT_TB)
	@mkdir -p $(BUILD_DIR)/misc_load_data_format
	$(VERILATOR) $(VERILATOR_COMMON) --timing \
		--Mdir $(BUILD_DIR)/misc_load_data_format \
		--top-module misc_load_data_format_tb \
		$(MISC_LOAD_DATA_FORMAT_RTL_SOURCES) $(MISC_LOAD_DATA_FORMAT_TB)

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
	$(BUILD_DIR)/pc_addressing/Vpc_addressing_tb \
	$(BUILD_DIR)/arm_branch_execute/Varm_branch_execute_tb \
	$(BUILD_DIR)/multiplier_timing/Vmultiplier_timing_tb \
	$(BUILD_DIR)/multiply_decoder/Vmultiply_decoder_tb \
	$(BUILD_DIR)/common_multiply_alu/Vcommon_multiply_alu_tb \
	$(BUILD_DIR)/common_multiply_execute/Vcommon_multiply_execute_tb \
	$(BUILD_DIR)/dsp_multiply_decoder/Vdsp_multiply_decoder_tb \
	$(BUILD_DIR)/dsp_multiply_alu/Vdsp_multiply_alu_tb \
	$(BUILD_DIR)/dsp_multiply_execute/Vdsp_multiply_execute_tb \
	$(BUILD_DIR)/clz_execute/Vclz_execute_tb \
	$(BUILD_DIR)/saturating_decoder/Vsaturating_decoder_tb \
	$(BUILD_DIR)/saturating_alu/Vsaturating_alu_tb \
	$(BUILD_DIR)/saturating_execute/Vsaturating_execute_tb \
	$(BUILD_DIR)/address_mode2/Vaddress_mode2_tb \
	$(BUILD_DIR)/single_transfer_prepare/Vsingle_transfer_prepare_tb \
	$(BUILD_DIR)/store_data_select/Vstore_data_select_tb \
	$(BUILD_DIR)/load_data_align/Vload_data_align_tb \
	$(BUILD_DIR)/single_load_complete/Vsingle_load_complete_tb \
	$(BUILD_DIR)/single_store_complete/Vsingle_store_complete_tb \
	$(BUILD_DIR)/address_mode3/Vaddress_mode3_tb \
	$(BUILD_DIR)/misc_transfer_prepare/Vmisc_transfer_prepare_tb \
	$(BUILD_DIR)/misc_load_data_format/Vmisc_load_data_format_tb

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

test-arm-branch: $(BUILD_DIR)/arm_branch_execute/Varm_branch_execute_tb
	$(BUILD_DIR)/arm_branch_execute/Varm_branch_execute_tb

test-multiplier-timing: $(BUILD_DIR)/multiplier_timing/Vmultiplier_timing_tb
	$(BUILD_DIR)/multiplier_timing/Vmultiplier_timing_tb

test-multiply-decoder: $(BUILD_DIR)/multiply_decoder/Vmultiply_decoder_tb
	$(BUILD_DIR)/multiply_decoder/Vmultiply_decoder_tb

test-common-multiply-alu: $(BUILD_DIR)/common_multiply_alu/Vcommon_multiply_alu_tb
	$(BUILD_DIR)/common_multiply_alu/Vcommon_multiply_alu_tb

test-common-multiply-execute: $(BUILD_DIR)/common_multiply_execute/Vcommon_multiply_execute_tb
	$(BUILD_DIR)/common_multiply_execute/Vcommon_multiply_execute_tb

test-dsp-multiply-decoder: $(BUILD_DIR)/dsp_multiply_decoder/Vdsp_multiply_decoder_tb
	$(BUILD_DIR)/dsp_multiply_decoder/Vdsp_multiply_decoder_tb

test-dsp-multiply-alu: $(BUILD_DIR)/dsp_multiply_alu/Vdsp_multiply_alu_tb
	$(BUILD_DIR)/dsp_multiply_alu/Vdsp_multiply_alu_tb

test-dsp-multiply-execute: $(BUILD_DIR)/dsp_multiply_execute/Vdsp_multiply_execute_tb
	$(BUILD_DIR)/dsp_multiply_execute/Vdsp_multiply_execute_tb

test-clz-execute: $(BUILD_DIR)/clz_execute/Vclz_execute_tb
	$(BUILD_DIR)/clz_execute/Vclz_execute_tb

test-saturating-decoder: $(BUILD_DIR)/saturating_decoder/Vsaturating_decoder_tb
	$(BUILD_DIR)/saturating_decoder/Vsaturating_decoder_tb

test-saturating-alu: $(BUILD_DIR)/saturating_alu/Vsaturating_alu_tb
	$(BUILD_DIR)/saturating_alu/Vsaturating_alu_tb

test-saturating-execute: $(BUILD_DIR)/saturating_execute/Vsaturating_execute_tb
	$(BUILD_DIR)/saturating_execute/Vsaturating_execute_tb

test-address-mode2: $(BUILD_DIR)/address_mode2/Vaddress_mode2_tb
	$(BUILD_DIR)/address_mode2/Vaddress_mode2_tb

test-single-transfer-prepare: $(BUILD_DIR)/single_transfer_prepare/Vsingle_transfer_prepare_tb
	$(BUILD_DIR)/single_transfer_prepare/Vsingle_transfer_prepare_tb

test-store-data-select: $(BUILD_DIR)/store_data_select/Vstore_data_select_tb
	$(BUILD_DIR)/store_data_select/Vstore_data_select_tb

test-load-data-align: $(BUILD_DIR)/load_data_align/Vload_data_align_tb
	$(BUILD_DIR)/load_data_align/Vload_data_align_tb

test-single-load-complete: $(BUILD_DIR)/single_load_complete/Vsingle_load_complete_tb
	$(BUILD_DIR)/single_load_complete/Vsingle_load_complete_tb

test-single-store-complete: $(BUILD_DIR)/single_store_complete/Vsingle_store_complete_tb
	$(BUILD_DIR)/single_store_complete/Vsingle_store_complete_tb

test-address-mode3: $(BUILD_DIR)/address_mode3/Vaddress_mode3_tb
	$(BUILD_DIR)/address_mode3/Vaddress_mode3_tb

test-misc-transfer-prepare: $(BUILD_DIR)/misc_transfer_prepare/Vmisc_transfer_prepare_tb
	$(BUILD_DIR)/misc_transfer_prepare/Vmisc_transfer_prepare_tb

test-misc-load-data-format: $(BUILD_DIR)/misc_load_data_format/Vmisc_load_data_format_tb
	$(BUILD_DIR)/misc_load_data_format/Vmisc_load_data_format_tb

test-rtl-unit: test-condition test-register-file test-status-registers test-shifter \
	test-data-alu test-immediate test-data-decoder test-data-execute test-pc \
	test-arm-branch test-multiplier-timing test-multiply-decoder \
	test-common-multiply-alu test-common-multiply-execute \
	test-dsp-multiply-decoder test-dsp-multiply-alu \
	test-dsp-multiply-execute test-clz-execute test-saturating-decoder \
	test-saturating-alu test-saturating-execute test-address-mode2 \
	test-single-transfer-prepare test-store-data-select test-load-data-align \
	test-single-load-complete test-single-store-complete test-address-mode3 \
	test-misc-transfer-prepare test-misc-load-data-format

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
