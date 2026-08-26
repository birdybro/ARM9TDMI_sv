module immediate_expander_tb;
  logic [7:0]  immediate_value;
  logic [3:0]  rotate_imm;
  logic        carry_in;
  logic [31:0] expanded_value;
  logic        carry_out;
  int unsigned cases_checked;

  arm9_immediate_expander dut (.*);

  task automatic apply_and_check(
    input logic [7:0] test_immediate,
    input logic [3:0] test_rotate,
    input logic test_carry
  );
    logic [31:0] expected_value;
    logic        expected_carry;
    int unsigned rotation;

    immediate_value = test_immediate;
    rotate_imm      = test_rotate;
    carry_in        = test_carry;
    #1ps;

    rotation = {27'b0, test_rotate, 1'b0};
    if (rotation == 0) begin
      expected_value = {24'b0, test_immediate};
      expected_carry = test_carry;
    end else begin
      expected_value = ({24'b0, test_immediate} >> rotation) |
                       ({24'b0, test_immediate} << (32 - rotation));
      expected_carry = expected_value[31];
    end

    assert ({carry_out, expanded_value} == {expected_carry, expected_value})
      else begin
        $error(
          "imm=%02x rotate=%0d carry=%0d expected=%01x%08x actual=%01x%08x",
          test_immediate,
          test_rotate,
          test_carry,
          expected_carry,
          expected_value,
          carry_out,
          expanded_value
        );
      end
    cases_checked++;
  endtask

  initial begin
    immediate_value = '0;
    rotate_imm      = '0;
    carry_in        = 1'b0;
    cases_checked   = 0;

    // REQ: COMMON-ARM-IMMEDIATE-001
    for (int unsigned immediate = 0; immediate < 256; immediate++) begin
      for (int unsigned rotate = 0; rotate < 16; rotate++) begin
        for (int unsigned carry = 0; carry < 2; carry++) begin
          apply_and_check(
            immediate[7:0],
            rotate[3:0],
            carry[0]
          );
        end
      end
    end

    assert (cases_checked == 8_192);
    $display("PASS all 4096 ARM immediate encodings and both carry inputs");
    $finish;
  end
endmodule
