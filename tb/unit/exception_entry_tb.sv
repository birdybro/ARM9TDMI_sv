module exception_entry_tb;
  import arm9_profile_pkg::*;
  import arm9_arch_pkg::*;

  logic exception_valid;
  arm9_exception_kind_e exception_kind;
  logic [31:0] current_cpsr;
  logic [31:0] instruction_address;
  logic [31:0] next_instruction_address;
  logic arm9tdmi_hivecs;
  logic arm946_cp15_high_vectors;

  logic tdmi_high_vectors_selected;
  arm9_mode_e tdmi_exception_mode;
  logic [4:0] tdmi_vector_offset;
  logic [31:0] tdmi_vector_address;
  logic tdmi_link_write_valid;
  arm9_mode_e tdmi_link_write_mode;
  logic [31:0] tdmi_link_write_value;
  logic tdmi_link_value_unpredictable;
  logic tdmi_spsr_write_valid;
  arm9_mode_e tdmi_spsr_write_mode;
  logic [31:0] tdmi_spsr_write_value;
  logic tdmi_spsr_value_unpredictable;
  logic tdmi_cpsr_write_valid;
  logic [31:0] tdmi_cpsr_write_value;
  logic [31:0] tdmi_cpsr_write_mask;
  logic tdmi_pipeline_flush;

  logic arm946_high_vectors_selected;
  arm9_mode_e arm946_exception_mode;
  logic [4:0] arm946_vector_offset;
  logic [31:0] arm946_vector_address;
  logic arm946_link_write_valid;
  arm9_mode_e arm946_link_write_mode;
  logic [31:0] arm946_link_write_value;
  logic arm946_link_value_unpredictable;
  logic arm946_spsr_write_valid;
  arm9_mode_e arm946_spsr_write_mode;
  logic [31:0] arm946_spsr_write_value;
  logic arm946_spsr_value_unpredictable;
  logic arm946_cpsr_write_valid;
  logic [31:0] arm946_cpsr_write_value;
  logic [31:0] arm946_cpsr_write_mask;
  logic arm946_pipeline_flush;
  int unsigned cases_checked;

  arm9_exception_entry #(
    .PROFILE(ARM9_PROFILE_ARM9TDMI)
  ) tdmi_dut (
    .exception_valid,
    .exception_kind,
    .current_cpsr,
    .instruction_address,
    .next_instruction_address,
    .arm9tdmi_hivecs,
    .arm946_cp15_high_vectors,
    .high_vectors_selected(tdmi_high_vectors_selected),
    .exception_mode(tdmi_exception_mode),
    .vector_offset(tdmi_vector_offset),
    .vector_address(tdmi_vector_address),
    .link_write_valid(tdmi_link_write_valid),
    .link_write_mode(tdmi_link_write_mode),
    .link_write_value(tdmi_link_write_value),
    .link_value_unpredictable(tdmi_link_value_unpredictable),
    .spsr_write_valid(tdmi_spsr_write_valid),
    .spsr_write_mode(tdmi_spsr_write_mode),
    .spsr_write_value(tdmi_spsr_write_value),
    .spsr_value_unpredictable(tdmi_spsr_value_unpredictable),
    .cpsr_write_valid(tdmi_cpsr_write_valid),
    .cpsr_write_value(tdmi_cpsr_write_value),
    .cpsr_write_mask(tdmi_cpsr_write_mask),
    .pipeline_flush(tdmi_pipeline_flush)
  );

  arm9_exception_entry #(
    .PROFILE(ARM9_PROFILE_ARM946ES)
  ) arm946_dut (
    .exception_valid,
    .exception_kind,
    .current_cpsr,
    .instruction_address,
    .next_instruction_address,
    .arm9tdmi_hivecs,
    .arm946_cp15_high_vectors,
    .high_vectors_selected(arm946_high_vectors_selected),
    .exception_mode(arm946_exception_mode),
    .vector_offset(arm946_vector_offset),
    .vector_address(arm946_vector_address),
    .link_write_valid(arm946_link_write_valid),
    .link_write_mode(arm946_link_write_mode),
    .link_write_value(arm946_link_write_value),
    .link_value_unpredictable(arm946_link_value_unpredictable),
    .spsr_write_valid(arm946_spsr_write_valid),
    .spsr_write_mode(arm946_spsr_write_mode),
    .spsr_write_value(arm946_spsr_write_value),
    .spsr_value_unpredictable(arm946_spsr_value_unpredictable),
    .cpsr_write_valid(arm946_cpsr_write_valid),
    .cpsr_write_value(arm946_cpsr_write_value),
    .cpsr_write_mask(arm946_cpsr_write_mask),
    .pipeline_flush(arm946_pipeline_flush)
  );

  task automatic expected_kind(
    input arm9_exception_kind_e kind,
    output arm9_mode_e mode,
    output logic [4:0] offset,
    output logic [31:0] link
  );
    case (kind)
      ARM9_EXCEPTION_RESET: begin
        mode = ARM9_MODE_SUPERVISOR;
        offset = 5'h00;
        link = 32'b0;
      end
      ARM9_EXCEPTION_UNDEFINED: begin
        mode = ARM9_MODE_UNDEFINED;
        offset = 5'h04;
        link = next_instruction_address;
      end
      ARM9_EXCEPTION_SWI: begin
        mode = ARM9_MODE_SUPERVISOR;
        offset = 5'h08;
        link = next_instruction_address;
      end
      ARM9_EXCEPTION_PREFETCH_ABORT: begin
        mode = ARM9_MODE_ABORT;
        offset = 5'h0c;
        link = instruction_address + 32'd4;
      end
      ARM9_EXCEPTION_DATA_ABORT: begin
        mode = ARM9_MODE_ABORT;
        offset = 5'h10;
        link = instruction_address + 32'd8;
      end
      ARM9_EXCEPTION_IRQ: begin
        mode = ARM9_MODE_IRQ;
        offset = 5'h18;
        link = next_instruction_address + 32'd4;
      end
      default: begin
        mode = ARM9_MODE_FIQ;
        offset = 5'h1c;
        link = next_instruction_address + 32'd4;
      end
    endcase
  endtask

  initial begin
    arm9_mode_e expected_mode;
    logic [4:0] expected_offset;
    logic [31:0] expected_link;
    logic [31:0] expected_cpsr;
    logic expected_link_valid;

    exception_valid = 1'b0;
    exception_kind = ARM9_EXCEPTION_RESET;
    current_cpsr = 32'b0;
    instruction_address = 32'b0;
    next_instruction_address = 32'b0;
    arm9tdmi_hivecs = 1'b0;
    arm946_cp15_high_vectors = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-EXCEPTION-ENTRY-001
    // REQ: COMMON-EXCEPTION-LR-001
    // REQ: ARM9TDMI-EXCEPTION-VECTORS-001
    // REQ: ARM946ES-EXCEPTION-VECTORS-001
    for (int unsigned valid_case = 0; valid_case < 2; valid_case++) begin
      for (int unsigned kind_case = 0; kind_case < 7; kind_case++) begin
        for (int unsigned vector_case = 0; vector_case < 4;
             vector_case++) begin
          for (int unsigned data_case = 0; data_case < 8; data_case++) begin
            exception_valid = valid_case[0];
            exception_kind = arm9_exception_kind_e'(kind_case[2:0]);
            current_cpsr = 32'ha800_0000 |
                           (data_case[0] ? 32'h0000_0040 : 32'b0) |
                           (data_case[1] ? 32'h0000_0020 : 32'b0) |
                           32'(ARM9_MODE_USER);
            instruction_address = 32'h1000_0000 +
                                  (32'(data_case) << 12);
            next_instruction_address = instruction_address +
              (data_case[2] ? 32'd2 : 32'd4);
            arm9tdmi_hivecs = vector_case[1];
            arm946_cp15_high_vectors = vector_case[0];
            expected_kind(exception_kind, expected_mode,
                          expected_offset, expected_link);
            expected_link_valid = valid_case[0] &&
                                  (exception_kind != ARM9_EXCEPTION_RESET);
            expected_cpsr = current_cpsr;
            expected_cpsr[4:0] = expected_mode;
            expected_cpsr[5] = 1'b0;
            expected_cpsr[7] = 1'b1;
            if ((exception_kind == ARM9_EXCEPTION_RESET) ||
                (exception_kind == ARM9_EXCEPTION_FIQ)) begin
              expected_cpsr[6] = 1'b1;
            end
            #1ps;

            assert (tdmi_high_vectors_selected == vector_case[1]);
            assert (arm946_high_vectors_selected == vector_case[0]);
            assert (tdmi_exception_mode == expected_mode);
            assert (arm946_exception_mode == expected_mode);
            assert (tdmi_vector_offset == expected_offset);
            assert (arm946_vector_offset == expected_offset);
            assert (tdmi_vector_address ==
                    ((vector_case[1] ? 32'hffff_0000 : 32'b0) |
                     {27'b0, expected_offset}));
            assert (arm946_vector_address ==
                    ((vector_case[0] ? 32'hffff_0000 : 32'b0) |
                     {27'b0, expected_offset}));
            assert (tdmi_link_write_valid == expected_link_valid);
            assert (arm946_link_write_valid == expected_link_valid);
            assert (tdmi_link_write_mode == expected_mode);
            assert (arm946_link_write_mode == expected_mode);
            assert (tdmi_link_write_value == expected_link);
            assert (arm946_link_write_value == expected_link);
            assert (tdmi_link_value_unpredictable ==
                    (valid_case[0] &&
                     (exception_kind == ARM9_EXCEPTION_RESET)));
            assert (arm946_link_value_unpredictable ==
                    tdmi_link_value_unpredictable);
            assert (tdmi_spsr_write_valid == expected_link_valid);
            assert (arm946_spsr_write_valid == expected_link_valid);
            assert (tdmi_spsr_write_mode == expected_mode);
            assert (arm946_spsr_write_mode == expected_mode);
            assert (tdmi_spsr_write_value == current_cpsr);
            assert (arm946_spsr_write_value == current_cpsr);
            assert (tdmi_spsr_value_unpredictable ==
                    tdmi_link_value_unpredictable);
            assert (arm946_spsr_value_unpredictable ==
                    tdmi_spsr_value_unpredictable);
            assert (tdmi_cpsr_write_valid == valid_case[0]);
            assert (arm946_cpsr_write_valid == valid_case[0]);
            assert (tdmi_cpsr_write_value == expected_cpsr);
            assert (arm946_cpsr_write_value == expected_cpsr);
            assert (tdmi_cpsr_write_mask == 32'h0000_00ff);
            assert (arm946_cpsr_write_mask == 32'h0000_00ff);
            assert (tdmi_pipeline_flush == valid_case[0]);
            assert (arm946_pipeline_flush == valid_case[0]);
            cases_checked++;
          end
        end
      end
    end

    assert (cases_checked == 448);
    $display("PASS profile-specific architectural exception entry (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
