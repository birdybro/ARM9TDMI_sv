module address_mode2_tb;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] base_value;
  logic [31:0] index_value;
  logic carry_in;
  logic decode_match;
  logic encoding_valid;
  logic unpredictable_encoding;
  logic [3:0] condition;
  logic immediate_offset;
  logic pre_index;
  logic add_offset;
  logic byte_transfer;
  logic writeback;
  logic load;
  logic unprivileged_access;
  logic [3:0] base_register;
  logic [3:0] data_register;
  logic [3:0] index_register;
  logic [4:0] shift_amount;
  arm9_shift_type_e shift_type;
  logic [31:0] offset_value;
  logic shift_carry_out;
  logic [31:0] effective_address;
  logic [31:0] writeback_address;
  int unsigned cases_checked;

  arm9_address_mode2 dut (.*);

  function automatic logic [32:0] reference_shift(
    input logic [31:0] value,
    input arm9_shift_type_e kind,
    input logic [4:0] amount,
    input logic carry
  );
    logic [31:0] shifted;
    logic shifted_carry;
    int unsigned count;
    begin
      count = {27'b0, amount};
      shifted = value;
      shifted_carry = carry;
      case (kind)
        ARM9_SHIFT_LSL: begin
          if (count != 0) begin
            shifted = value << count;
            shifted_carry = value[32-count];
          end
        end
        ARM9_SHIFT_LSR: begin
          if (count == 0) begin
            shifted = 32'b0;
            shifted_carry = value[31];
          end else begin
            shifted = value >> count;
            shifted_carry = value[count-1];
          end
        end
        ARM9_SHIFT_ASR: begin
          if (count == 0) begin
            shifted = {32{value[31]}};
            shifted_carry = value[31];
          end else begin
            shifted = $unsigned($signed(value) >>> count);
            shifted_carry = value[count-1];
          end
        end
        default: begin
          if (count == 0) begin
            shifted = {carry, value[31:1]};
            shifted_carry = value[0];
          end else begin
            shifted = (value >> count) | (value << (32-count));
            shifted_carry = value[count-1];
          end
        end
      endcase
      return {shifted_carry, shifted};
    end
  endfunction

  function automatic logic [31:0] test_value(input int unsigned index);
    case (index)
      0: return 32'h0000_0000;
      1: return 32'h0000_0001;
      2: return 32'h8000_0000;
      3: return 32'hffff_ffff;
      default: return 32'h1234_5678;
    endcase
  endfunction

  initial begin
    logic expected_decode;
    logic expected_writeback;
    logic expected_unprivileged;
    logic expected_unpredictable;
    logic [32:0] expected_shift;
    logic [31:0] expected_offset;
    logic [31:0] expected_adjusted;

    instruction   = 32'he591_2004;
    base_value    = 32'h1000_0000;
    index_value   = 32'h0000_0004;
    carry_in      = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-ADDRMODE2-CONTROL-001
    for (int unsigned upper_control = 0; upper_control < 256;
         upper_control++) begin
      for (int unsigned bit_four = 0; bit_four < 2; bit_four++) begin
        instruction = 32'he001_2004;
        instruction[27:20] = upper_control[7:0];
        instruction[4] = bit_four[0];
        expected_decode = (upper_control[7:6] == 2'b01) &&
          (!upper_control[5] || !bit_four[0]);
        #1ps;
        assert (decode_match == expected_decode);
        assert (encoding_valid == expected_decode);
        assert (!unpredictable_encoding);
        cases_checked++;
      end
    end

    // REQ: COMMON-ARM-ADDRMODE2-CALC-001
    for (int unsigned controls = 0; controls < 32; controls++) begin
      for (int unsigned immediate = 0; immediate < 3; immediate++) begin
        for (int unsigned base_index = 0; base_index < 4; base_index++) begin
          for (int unsigned carry = 0; carry < 2; carry++) begin
            instruction = 32'he401_2000;
            instruction[24:20] = controls[4:0];
            instruction[11:0] = (immediate == 0) ? 12'h000 :
                                 (immediate == 1) ? 12'h001 : 12'hfff;
            base_value = test_value(base_index);
            carry_in   = carry[0];
            expected_offset = {20'b0, instruction[11:0]};
            expected_adjusted = instruction[23] ?
              (base_value + expected_offset) :
              (base_value - expected_offset);
            expected_writeback = !instruction[24] || instruction[21];
            expected_unprivileged = !instruction[24] && instruction[21];
            #1ps;
            assert (decode_match && encoding_valid);
            assert (immediate_offset);
            assert (offset_value == expected_offset);
            assert (writeback_address == expected_adjusted);
            assert (effective_address ==
                    (instruction[24] ? expected_adjusted : base_value));
            assert (pre_index == instruction[24]);
            assert (add_offset == instruction[23]);
            assert (byte_transfer == instruction[22]);
            assert (writeback == expected_writeback);
            assert (load == instruction[20]);
            assert (unprivileged_access == expected_unprivileged);
            cases_checked++;
          end
        end
      end
    end

    for (int unsigned controls = 0; controls < 32; controls++) begin
      for (int unsigned kind = 0; kind < 4; kind++) begin
        for (int unsigned amount = 0; amount < 32; amount++) begin
          for (int unsigned index_index = 0; index_index < 5;
               index_index++) begin
            for (int unsigned base_index = 0; base_index < 4;
                 base_index++) begin
              for (int unsigned carry = 0; carry < 2; carry++) begin
                instruction = 32'he601_2003;
                instruction[24:20] = controls[4:0];
                instruction[11:7] = amount[4:0];
                instruction[6:5] = kind[1:0];
                base_value  = test_value(base_index);
                index_value = test_value(index_index);
                carry_in    = carry[0];
                expected_shift = reference_shift(
                  index_value, arm9_shift_type_e'(kind[1:0]),
                  amount[4:0], carry_in
                );
                expected_offset = expected_shift[31:0];
                expected_adjusted = instruction[23] ?
                  (base_value + expected_offset) :
                  (base_value - expected_offset);
                #1ps;
                assert (decode_match && encoding_valid);
                assert (!immediate_offset);
                assert (offset_value == expected_offset);
                assert (shift_carry_out == expected_shift[32]);
                assert (writeback_address == expected_adjusted);
                assert (effective_address ==
                        (instruction[24] ? expected_adjusted : base_value));
                assert (shift_type == arm9_shift_type_e'(kind[1:0]));
                assert (shift_amount == amount[4:0]);
                cases_checked++;
              end
            end
          end
        end
      end
    end

    // REQ: COMMON-ARM-ADDRMODE2-CONSTRAINTS-001
    for (int unsigned register_form = 0; register_form < 2;
         register_form++) begin
      for (int unsigned control = 0; control < 32; control++) begin
        for (int unsigned rn = 0; rn < 16; rn++) begin
          for (int unsigned rd = 0; rd < 16; rd++) begin
            for (int unsigned rm = 0; rm < 16; rm++) begin
              instruction = register_form[0] ? 32'he601_2003 :
                                               32'he401_2004;
              instruction[24:20] = control[4:0];
              instruction[19:16] = rn[3:0];
              instruction[15:12] = rd[3:0];
              instruction[3:0]   = rm[3:0];
              expected_writeback = !instruction[24] || instruction[21];
              expected_unpredictable =
                (expected_writeback && (rn == 15)) ||
                (expected_writeback && (rd == rn)) ||
                (register_form[0] && expected_writeback && (rn == rm)) ||
                (register_form[0] && (rm == 15)) ||
                (instruction[22] && (rd == 15));
              #1ps;
              assert (decode_match);
              assert (unpredictable_encoding == expected_unpredictable);
              assert (encoding_valid == !expected_unpredictable);
              assert (base_register == rn[3:0]);
              assert (data_register == rd[3:0]);
              assert (index_register == rm[3:0]);
              cases_checked++;
            end
          end
        end
      end
    end

    instruction = 32'hf591_2004;
    #1ps;
    assert (!decode_match && !encoding_valid && !unpredictable_encoding);
    assert (condition == 4'hf);
    cases_checked++;

    assert (cases_checked == 427_265);
    $display("PASS ARM Addressing Mode 2 decode/address generation (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
