module swi_execute_tb;
  logic [31:0] instruction;
  logic [31:0] instruction_address;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;
  logic decode_match;
  logic [3:0] condition;
  logic [23:0] comment_field;
  logic condition_passed;
  logic unconditional_space;
  logic exception_request;
  logic [31:0] next_instruction_address;
  int unsigned cases_checked;

  arm9_swi_execute dut (.*);

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

  initial begin
    logic expected_condition;

    instruction = 32'b0;
    instruction_address = 32'b0;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-SWI-EXECUTE-001
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned flags = 0; flags < 16; flags++) begin
        for (int unsigned comment_case = 0; comment_case < 8;
             comment_case++) begin
          instruction = {condition_case[3:0], 4'b1111,
                         21'h15_5aa, comment_case[2:0]};
          instruction_address = 32'h1000_0000 +
                                (32'(comment_case) << 2);
          negative = flags[3];
          zero = flags[2];
          carry = flags[1];
          overflow = flags[0];
          expected_condition = reference_condition(
            condition_case[3:0], negative, zero, carry, overflow
          );
          #1ps;

          assert (decode_match == (condition_case != 15));
          assert (condition == condition_case[3:0]);
          assert (comment_field == instruction[23:0]);
          assert (condition_passed == expected_condition);
          assert (unconditional_space == (condition_case == 15));
          assert (exception_request ==
                  ((condition_case != 15) && expected_condition));
          assert (next_instruction_address ==
                  instruction_address + 32'd4);
          cases_checked++;
        end
      end
    end

    instruction = 32'heeff_ffff;
    #1ps;
    assert (!decode_match && !exception_request);

    assert (cases_checked == 2048);
    $display("PASS condition-gated ARM SWI execution (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
