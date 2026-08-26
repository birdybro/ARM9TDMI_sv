module data_processing_execute_tb;
  import arm9_isa_pkg::*;

  logic [31:0] instruction;
  logic [31:0] first_operand_value;
  logic [31:0] shifted_register_value;
  logic [7:0]  shift_register_value;
  logic        negative_in;
  logic        zero_in;
  logic        carry_in;
  logic        overflow_in;
  logic        decode_match;
  logic        encoding_valid;
  logic        unpredictable_encoding;
  logic        condition_passed;
  logic        unconditional_space;
  logic        execute_valid;
  logic [3:0]  first_register;
  logic [3:0]  destination_register;
  logic [3:0]  shift_register;
  logic [3:0]  shifted_register;
  logic [31:0] result;
  logic        result_write_enable;
  logic        flags_write_enable;
  logic        negative_out;
  logic        zero_out;
  logic        carry_out;
  logic        overflow_out;
  int unsigned cases_checked;

  arm9_data_processing_execute dut (.*);

  function automatic logic reference_condition(
    input logic [3:0] cond,
    input logic n,
    input logic z,
    input logic c,
    input logic v
  );
    case (cond)
      4'h0: return z;
      4'h1: return !z;
      4'h2: return c;
      4'h3: return !c;
      4'h4: return n;
      4'h5: return !n;
      4'h6: return v;
      4'h7: return !v;
      4'h8: return c && !z;
      4'h9: return !c || z;
      4'ha: return n == v;
      4'hb: return n != v;
      4'hc: return !z && (n == v);
      4'hd: return z || (n != v);
      4'he: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic [31:0] rotate_immediate(
    input logic [7:0] immediate,
    input logic [3:0] rotation_field
  );
    int unsigned rotation;

    rotation = {27'b0, rotation_field, 1'b0};
    if (rotation == 0) begin
      return {24'b0, immediate};
    end
    return ({24'b0, immediate} >> rotation) |
           ({24'b0, immediate} << (32 - rotation));
  endfunction

  task automatic set_immediate_movs(
    input logic [3:0] condition,
    input logic [3:0] destination,
    input logic [7:0] immediate,
    input logic [3:0] rotation
  );
    instruction        = '0;
    instruction[31:28] = condition;
    instruction[25]    = 1'b1;
    instruction[24:21] = ARM9_DATA_MOV;
    instruction[20]    = 1'b1;
    instruction[15:12] = destination;
    instruction[11:8]  = rotation;
    instruction[7:0]   = immediate;
  endtask

  task automatic check_immediate(
    input logic [7:0] immediate,
    input logic [3:0] rotation,
    input logic old_carry
  );
    logic [31:0] expected;

    set_immediate_movs(4'he, 4'h7, immediate, rotation);
    carry_in = old_carry;
    #1ps;
    expected = rotate_immediate(immediate, rotation);
    assert (decode_match && encoding_valid && execute_valid);
    assert (!unpredictable_encoding && !unconditional_space);
    assert (first_register == 4'b0000);
    assert (destination_register == 4'h7);
    assert (shift_register == rotation);
    assert (shifted_register == immediate[3:0]);
    assert (result_write_enable && flags_write_enable);
    assert (result == expected);
    assert (negative_out == expected[31]);
    assert (zero_out == (expected == 0));
    assert (carry_out == ((rotation == 0) ? old_carry : expected[31]));
    assert (overflow_out == overflow_in);
    cases_checked++;
  endtask

  initial begin
    instruction            = '0;
    first_operand_value    = 32'h1357_9bdf;
    shifted_register_value = 32'h8000_0001;
    shift_register_value   = '0;
    negative_in            = 1'b0;
    zero_in                = 1'b0;
    carry_in               = 1'b0;
    overflow_in            = 1'b1;
    cases_checked          = 0;

    // REQ: COMMON-ARM-DATA-EXECUTE-001
    for (int unsigned immediate = 0; immediate < 256; immediate++) begin
      for (int unsigned rotation = 0; rotation < 16; rotation++) begin
        for (int unsigned old_carry = 0; old_carry < 2; old_carry++) begin
          check_immediate(immediate[7:0], rotation[3:0], old_carry[0]);
        end
      end
    end

    // Immediate-shift LSR #32, selected by an encoded shift amount of zero.
    instruction        = 32'he000_0000;
    instruction[24:21] = ARM9_DATA_MOV;
    instruction[20]    = 1'b1;
    instruction[6:5]   = ARM9_SHIFT_LSR;
    shifted_register_value = 32'h8000_0001;
    #1ps;
    assert (result == 32'b0 && carry_out && zero_out);
    cases_checked++;

    // Register-specified ROR by 32 preserves the operand and exports bit 31.
    instruction[11:8] = 4'h3;
    instruction[6:5]  = ARM9_SHIFT_ROR;
    instruction[4]    = 1'b1;
    shift_register_value = 8'd32;
    #1ps;
    assert (result == 32'h8000_0001 && carry_out && negative_out);
    cases_checked++;

    // A failed condition suppresses both architectural writes.
    set_immediate_movs(4'h0, 4'h2, 8'h55, 4'b0);
    zero_in = 1'b0;
    #1ps;
    assert (!condition_passed && !execute_valid);
    assert (!result_write_enable && !flags_write_enable);
    cases_checked++;

    // Exercise all condition/flag combinations at the integrated boundary.
    for (int unsigned cond = 0; cond < 16; cond++) begin
      for (int unsigned flags = 0; flags < 16; flags++) begin
        set_immediate_movs(cond[3:0], 4'h1, 8'h01, 4'b0);
        negative_in = flags[3];
        zero_in     = flags[2];
        carry_in    = flags[1];
        overflow_in = flags[0];
        #1ps;
        assert (condition_passed == reference_condition(
          cond[3:0], flags[3], flags[2], flags[1], flags[0]
        ));
        assert (execute_valid == condition_passed);
        assert (result_write_enable == condition_passed);
        assert (flags_write_enable == condition_passed);
        assert (unconditional_space == (cond == 15));
        cases_checked++;
      end
    end

    assert (cases_checked == 8_451);
    $display("PASS integrated ARM data-processing execute stage (%0d cases)", cases_checked);
    $finish;
  end
endmodule
