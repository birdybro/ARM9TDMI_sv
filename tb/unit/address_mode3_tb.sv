module address_mode3_tb;
  import arm9_isa_pkg::*;

  logic [31:0]                  instruction;
  logic [31:0]                  base_value;
  logic [31:0]                  index_value;
  logic                         decode_match;
  logic                         encoding_valid;
  logic                         unpredictable_encoding;
  logic                         unaligned_access_unpredictable;
  logic [3:0]                   condition;
  arm9_misc_transfer_kind_e     transfer_kind;
  logic                         immediate_offset;
  logic                         pre_index;
  logic                         add_offset;
  logic                         writeback;
  logic                         load;
  logic                         signed_transfer;
  logic                         halfword_transfer;
  logic [3:0]                   base_register;
  logic [3:0]                   data_register;
  logic [3:0]                   index_register;
  logic [31:0]                  offset_value;
  logic [31:0]                  effective_address;
  logic [31:0]                  writeback_address;
  int unsigned                  cases_checked;

  arm9_address_mode3 dut (.*);

  function automatic logic expected_common_operation(
    input logic load_bit,
    input logic s,
    input logic h
  );
    return (!s && h) || (load_bit && s);
  endfunction

  initial begin
    logic expected_decode;
    logic expected_writeback;
    logic expected_unpredictable;
    logic [31:0] expected_offset;
    logic [31:0] expected_adjusted;

    instruction = 32'he1d1_20b4;
    base_value = 32'h1000_0000;
    index_value = 32'h0000_0004;
    cases_checked = 0;

    // REQ: COMMON-ARM-ADDRMODE3-CONTROL-001
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned upper_control = 0; upper_control < 256;
           upper_control++) begin
        for (int unsigned low_control = 0; low_control < 16;
             low_control++) begin
          instruction = '0;
          instruction[31:28] = condition_case[3:0];
          instruction[27:20] = upper_control[7:0];
          instruction[7:4] = low_control[3:0];
          expected_decode = (condition_case != 15) &&
            (upper_control[7:5] == 3'b000) && low_control[3] &&
            low_control[0] && expected_common_operation(
              upper_control[0], low_control[2], low_control[1]
            );
          #1ps;
          assert (decode_match == expected_decode);
          assert (condition == condition_case[3:0]);
          assert (load == instruction[20]);
          assert (signed_transfer == instruction[6]);
          assert (halfword_transfer == instruction[5]);
          cases_checked++;
        end
      end
    end

    // REQ: COMMON-ARM-ADDRMODE3-CALC-001
    for (int unsigned controls = 0; controls < 16; controls++) begin
      for (int unsigned offset_case = 0; offset_case < 3;
           offset_case++) begin
        for (int unsigned base_case = 0; base_case < 4; base_case++) begin
          instruction = 32'he1d1_20b0;
          instruction[24:21] = controls[3:0];
          instruction[11:8] = (offset_case == 0) ? 4'h0 :
                              (offset_case == 1) ? 4'h1 : 4'hf;
          instruction[3:0] = (offset_case == 0) ? 4'h0 :
                             (offset_case == 1) ? 4'h2 : 4'hf;
          base_value = (base_case == 0) ? 32'h0000_0000 :
                       (base_case == 1) ? 32'h0000_0001 :
                       (base_case == 2) ? 32'hffff_ffff :
                                          32'h1234_5678;
          index_value = (offset_case == 0) ? 32'h0000_0000 :
                        (offset_case == 1) ? 32'h0000_0012 :
                                             32'hffff_ffff;
          expected_offset = instruction[22] ?
            {24'b0, instruction[11:8], instruction[3:0]} : index_value;
          expected_adjusted = instruction[23] ?
            (base_value + expected_offset) : (base_value - expected_offset);
          #1ps;
          assert (decode_match);
          assert (immediate_offset == instruction[22]);
          assert (pre_index == instruction[24]);
          assert (add_offset == instruction[23]);
          assert (offset_value == expected_offset);
          assert (writeback_address == expected_adjusted);
          assert (effective_address ==
                  (instruction[24] ? expected_adjusted : base_value));
          cases_checked++;
        end
      end
    end

    // REQ: COMMON-ARM-ADDRMODE3-CONSTRAINTS-001
    for (int unsigned controls = 0; controls < 16; controls++) begin
      for (int unsigned reserved_case = 0; reserved_case < 2;
           reserved_case++) begin
        for (int unsigned rn = 0; rn < 16; rn++) begin
          for (int unsigned rd = 0; rd < 16; rd++) begin
            for (int unsigned rm = 0; rm < 16; rm++) begin
              instruction = 32'he191_20b3;
              instruction[24:21] = controls[3:0];
              instruction[19:16] = rn[3:0];
              instruction[15:12] = rd[3:0];
              instruction[11:8] = reserved_case[0] ? 4'ha : 4'h0;
              instruction[3:0] = rm[3:0];
              expected_writeback = !instruction[24] || instruction[21];
              expected_unpredictable =
                (!instruction[22] && reserved_case[0]) ||
                (!instruction[24] && instruction[21]) ||
                (expected_writeback && (rn == 15)) ||
                (expected_writeback && (rd == rn)) ||
                (!instruction[22] && expected_writeback && (rn == rm)) ||
                (!instruction[22] && (rm == 15)) || (rd == 15);
              #1ps;
              assert (decode_match);
              assert (unpredictable_encoding == expected_unpredictable);
              assert (encoding_valid == !expected_unpredictable);
              assert (writeback == expected_writeback);
              assert (base_register == rn[3:0]);
              assert (data_register == rd[3:0]);
              assert (index_register == rm[3:0]);
              cases_checked++;
            end
          end
        end
      end
    end

    // REQ: COMMON-ARM-ADDRMODE3-ALIGNMENT-001
    for (int unsigned operation_case = 0; operation_case < 4;
         operation_case++) begin
      for (int unsigned low_case = 0; low_case < 2; low_case++) begin
        case (operation_case)
          0: instruction = 32'he1c1_20b0;
          1: instruction = 32'he1d1_20b0;
          2: instruction = 32'he1d1_20d0;
          default: instruction = 32'he1d1_20f0;
        endcase
        base_value = 32'h2000_0000 | low_case;
        #1ps;
        assert (encoding_valid);
        assert (unaligned_access_unpredictable ==
                ((operation_case != 2) && (low_case != 0)));
        case (operation_case)
          0: assert (transfer_kind == ARM9_MISC_TRANSFER_STRH);
          1: assert (transfer_kind == ARM9_MISC_TRANSFER_LDRH);
          2: assert (transfer_kind == ARM9_MISC_TRANSFER_LDRSB);
          default: assert (transfer_kind == ARM9_MISC_TRANSFER_LDRSH);
        endcase
        cases_checked++;
      end
    end

    assert (cases_checked == 196_808);
    $display("PASS ARM Addressing Mode 3 common transfers (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
