module mrs_execute_tb;
  import arm9_arch_pkg::*;

  logic [31:0] instruction;
  arm9_mode_e current_mode;
  logic [31:0] cpsr_value;
  logic [31:0] current_spsr_value;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;
  logic decode_match;
  logic encoding_valid;
  logic unpredictable_encoding;
  logic condition_passed;
  logic unconditional_space;
  logic spsr_select;
  logic unpredictable_operation;
  logic execute_valid;
  logic destination_write_valid;
  logic [3:0] destination_write_register;
  logic [31:0] destination_write_value;
  int unsigned cases_checked;

  arm9_mrs_execute dut (.*);

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

  function automatic arm9_mode_e mode_for_case(input int unsigned value);
    case (value)
      0: return ARM9_MODE_USER;
      1: return ARM9_MODE_FIQ;
      2: return ARM9_MODE_IRQ;
      3: return ARM9_MODE_SUPERVISOR;
      4: return ARM9_MODE_ABORT;
      5: return ARM9_MODE_UNDEFINED;
      default: return ARM9_MODE_SYSTEM;
    endcase
  endfunction

  initial begin
    logic expected_condition;
    logic expected_unpredictable;
    logic expected_execute;

    instruction = 32'he10f_0000;
    current_mode = ARM9_MODE_USER;
    cpsr_value = 32'hf000_0010;
    current_spsr_value = 32'h8000_00d3;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-MRS-EXECUTE-001
    for (int unsigned condition_case = 0; condition_case < 15;
         condition_case++) begin
      for (int unsigned flags = 0; flags < 16; flags++) begin
        for (int unsigned mode_case = 0; mode_case < 7; mode_case++) begin
          for (int unsigned spsr_case = 0; spsr_case < 2; spsr_case++) begin
            for (int unsigned register_case = 0; register_case < 15;
                 register_case++) begin
              instruction = {condition_case[3:0], 5'b00010,
                             spsr_case[0], 2'b00, 4'hf,
                             register_case[3:0], 12'b0};
              current_mode = mode_for_case(mode_case);
              cpsr_value = 32'hf000_0000 | 32'(current_mode);
              current_spsr_value = 32'h0800_00c0 |
                                   32'(current_mode);
              negative = flags[3];
              zero = flags[2];
              carry = flags[1];
              overflow = flags[0];
              expected_condition = reference_condition(
                condition_case[3:0], negative, zero, carry, overflow
              );
              expected_unpredictable = expected_condition && spsr_case[0] &&
                                       !mode_has_spsr(current_mode);
              expected_execute = expected_condition &&
                                 !expected_unpredictable;
              #1ps;

              assert (decode_match && encoding_valid &&
                      !unpredictable_encoding);
              assert (condition_passed == expected_condition);
              assert (!unconditional_space);
              assert (spsr_select == spsr_case[0]);
              assert (unpredictable_operation == expected_unpredictable);
              assert (execute_valid == expected_execute);
              assert (destination_write_valid == expected_execute);
              assert (destination_write_register == register_case[3:0]);
              assert (destination_write_value ==
                      (spsr_case[0] ? current_spsr_value : cpsr_value));
              cases_checked++;
            end
          end
        end
      end
    end

    instruction = 32'he10f_f000;
    #1ps;
    assert (decode_match && !encoding_valid && unpredictable_encoding &&
            !execute_valid && !destination_write_valid);
    instruction = 32'he129_f000;
    #1ps;
    assert (decode_match && encoding_valid && !execute_valid &&
            !destination_write_valid);

    assert (cases_checked == 50_400);
    $display("PASS condition-gated common ARM MRS execution (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
