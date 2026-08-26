module barrel_shifter_tb;
  import arm9_isa_pkg::*;

  logic [31:0]      value;
  arm9_shift_type_e shift_type;
  logic [7:0]       shift_amount;
  logic             amount_from_register;
  logic             carry_in;
  logic [31:0]      result;
  logic             carry_out;
  logic [31:0]      operand_values [0:11];
  int unsigned      cases_checked;

  arm9_barrel_shifter dut (.*);

  function automatic logic [32:0] reference_shift(
    input logic [31:0] reference_value,
    input arm9_shift_type_e reference_type,
    input logic [7:0] reference_amount,
    input logic reference_is_register,
    input logic reference_carry
  );
    logic [31:0] reference_result;
    logic        reference_carry_out;
    int unsigned amount;
    int unsigned rotation;

    amount              = {24'b0, reference_amount};
    rotation            = {27'b0, reference_amount[4:0]};
    reference_result    = reference_value;
    reference_carry_out = reference_carry;

    if (!reference_is_register) begin
      case (reference_type)
        ARM9_SHIFT_LSL: begin
          if (amount != 0) begin
            reference_result = reference_value << amount;
            reference_carry_out = reference_value[32 - amount];
          end
        end
        ARM9_SHIFT_LSR: begin
          if (amount == 0) begin
            reference_result = 32'b0;
            reference_carry_out = reference_value[31];
          end else begin
            reference_result = reference_value >> amount;
            reference_carry_out = reference_value[amount - 1];
          end
        end
        ARM9_SHIFT_ASR: begin
          if (amount == 0) begin
            reference_result = {32{reference_value[31]}};
            reference_carry_out = reference_value[31];
          end else begin
            reference_result = $unsigned($signed(reference_value) >>> amount);
            reference_carry_out = reference_value[amount - 1];
          end
        end
        ARM9_SHIFT_ROR: begin
          if (amount == 0) begin
            reference_result = {reference_carry, reference_value[31:1]};
            reference_carry_out = reference_value[0];
          end else begin
            reference_result = (reference_value >> amount) |
                               (reference_value << (32 - amount));
            reference_carry_out = reference_value[amount - 1];
          end
        end
        default: begin
          reference_result = 'x;
          reference_carry_out = 1'bx;
        end
      endcase
    end else if (amount == 0) begin
      reference_result    = reference_value;
      reference_carry_out = reference_carry;
    end else begin
      case (reference_type)
        ARM9_SHIFT_LSL: begin
          if (amount < 32) begin
            reference_result = reference_value << amount;
            reference_carry_out = reference_value[32 - amount];
          end else if (amount == 32) begin
            reference_result = 32'b0;
            reference_carry_out = reference_value[0];
          end else begin
            reference_result = 32'b0;
            reference_carry_out = 1'b0;
          end
        end
        ARM9_SHIFT_LSR: begin
          if (amount < 32) begin
            reference_result = reference_value >> amount;
            reference_carry_out = reference_value[amount - 1];
          end else if (amount == 32) begin
            reference_result = 32'b0;
            reference_carry_out = reference_value[31];
          end else begin
            reference_result = 32'b0;
            reference_carry_out = 1'b0;
          end
        end
        ARM9_SHIFT_ASR: begin
          if (amount < 32) begin
            reference_result = $unsigned($signed(reference_value) >>> amount);
            reference_carry_out = reference_value[amount - 1];
          end else begin
            reference_result = {32{reference_value[31]}};
            reference_carry_out = reference_value[31];
          end
        end
        ARM9_SHIFT_ROR: begin
          if (rotation == 0) begin
            reference_result = reference_value;
            reference_carry_out = reference_value[31];
          end else begin
            reference_result = (reference_value >> rotation) |
                               (reference_value << (32 - rotation));
            reference_carry_out = reference_value[rotation - 1];
          end
        end
        default: begin
          reference_result = 'x;
          reference_carry_out = 1'bx;
        end
      endcase
    end

    return {reference_carry_out, reference_result};
  endfunction

  task automatic apply_and_check(
    input logic [31:0] test_value,
    input arm9_shift_type_e test_type,
    input logic [7:0] test_amount,
    input logic test_is_register,
    input logic test_carry
  );
    logic [32:0] expected;

    value                = test_value;
    shift_type           = test_type;
    shift_amount         = test_amount;
    amount_from_register = test_is_register;
    carry_in             = test_carry;
    #1ns;
    expected = reference_shift(
      test_value,
      test_type,
      test_amount,
      test_is_register,
      test_carry
    );
    assert ({carry_out, result} == expected) else begin
      $error(
        "value=%08x type=%0d amount=%0d register=%0d carry=%0d expected=%09x actual=%01x%08x",
        test_value,
        test_type,
        test_amount,
        test_is_register,
        test_carry,
        expected,
        carry_out,
        result
      );
    end
    cases_checked++;
  endtask

  initial begin
    operand_values[0]  = 32'h0000_0000;
    operand_values[1]  = 32'h0000_0001;
    operand_values[2]  = 32'h0000_0002;
    operand_values[3]  = 32'h7fff_ffff;
    operand_values[4]  = 32'h8000_0000;
    operand_values[5]  = 32'hffff_ffff;
    operand_values[6]  = 32'ha5a5_5a5a;
    operand_values[7]  = 32'h0123_4567;
    operand_values[8]  = 32'h89ab_cdef;
    operand_values[9]  = 32'h0001_0000;
    operand_values[10] = 32'h8000_0001;
    operand_values[11] = 32'h5555_aaaa;
    cases_checked      = 0;

    // REQ: COMMON-SHIFTER-IMMEDIATE-001
    for (int unsigned operand = 0; operand < 12; operand++) begin
      for (int unsigned carry = 0; carry < 2; carry++) begin
        for (int unsigned kind = 0; kind < 4; kind++) begin
          for (int unsigned amount = 0; amount < 32; amount++) begin
            apply_and_check(
              operand_values[operand],
              arm9_shift_type_e'(kind[1:0]),
              amount[7:0],
              1'b0,
              carry[0]
            );
          end
        end
      end
    end

    // REQ: COMMON-SHIFTER-REGISTER-001
    for (int unsigned operand = 0; operand < 12; operand++) begin
      for (int unsigned carry = 0; carry < 2; carry++) begin
        for (int unsigned kind = 0; kind < 4; kind++) begin
          for (int unsigned amount = 0; amount < 256; amount++) begin
            apply_and_check(
              operand_values[operand],
              arm9_shift_type_e'(kind[1:0]),
              amount[7:0],
              1'b1,
              carry[0]
            );
          end
        end
      end
    end

    assert (cases_checked == 27_648);
    $display("PASS ARM barrel shifter (%0d boundary-class cases)", cases_checked);
    $finish;
  end
endmodule
