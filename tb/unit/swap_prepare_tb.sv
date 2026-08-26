module swap_prepare_tb;
  logic [31:0] instruction;
  logic [31:0] base_value;
  logic [31:0] source_register_value;
  logic        negative;
  logic        zero;
  logic        carry;
  logic        overflow;
  logic        decode_match;
  logic        encoding_valid;
  logic        unpredictable_encoding;
  logic        condition_passed;
  logic        unconditional_space;
  logic        execute_valid;
  logic        byte_swap;
  logic [3:0]  base_register;
  logic [3:0]  destination_register;
  logic [3:0]  source_register;
  logic        atomic_sequence_valid;
  logic        atomic_lock_required;
  logic        read_then_write_required;
  logic        memory_byte_transfer;
  logic [31:0] read_access_address;
  logic [31:0] write_access_address;
  logic [1:0]  original_address_low;
  logic        loaded_word_rotation_required;
  logic [31:0] store_value;
  logic [7:0]  store_byte_value;
  int unsigned cases_checked;

  arm9_swap_prepare dut (.*);

  function automatic logic reference_condition(
    input logic [3:0] condition,
    input logic n,
    input logic z,
    input logic c,
    input logic v
  );
    case (condition)
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
    logic [31:0] expected_address;

    instruction = 32'he101_2093;
    base_value = 32'h1000_0000;
    source_register_value = 32'h89ab_cdef;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-SWP-PREPARE-001
    // REQ: COMMON-ARM-SWP-UNALIGNED-WORD-001
    for (int unsigned byte_case = 0; byte_case < 2; byte_case++) begin
      for (int unsigned condition_case = 0; condition_case < 15;
           condition_case++) begin
        for (int unsigned flags = 0; flags < 16; flags++) begin
          for (int unsigned low_case = 0; low_case < 4; low_case++) begin
            instruction = 32'he101_2093;
            instruction[31:28] = condition_case[3:0];
            instruction[22] = byte_case[0];
            base_value = 32'h1000_0000 | low_case;
            source_register_value = 32'h89ab_c000 |
                                    (32'(flags) << 4) | low_case;
            negative = flags[3];
            zero = flags[2];
            carry = flags[1];
            overflow = flags[0];
            expected_condition = reference_condition(
              condition_case[3:0], negative, zero, carry, overflow
            );
            expected_address = byte_case[0] ? base_value :
                               {base_value[31:2], 2'b00};
            #1ps;

            assert (decode_match && encoding_valid);
            assert (!unpredictable_encoding);
            assert (condition_passed == expected_condition);
            assert (execute_valid == expected_condition);
            assert (byte_swap == byte_case[0]);
            assert (atomic_sequence_valid == expected_condition);
            assert (atomic_lock_required == expected_condition);
            assert (read_then_write_required == expected_condition);
            assert (memory_byte_transfer ==
                    (expected_condition && byte_case[0]));
            assert (read_access_address == expected_address);
            assert (write_access_address == expected_address);
            assert (original_address_low == low_case[1:0]);
            assert (loaded_word_rotation_required ==
                    (expected_condition && !byte_case[0] &&
                     (low_case != 0)));
            assert (store_value == source_register_value);
            assert (store_byte_value == source_register_value[7:0]);
            assert (base_register == 4'h1);
            assert (destination_register == 4'h2);
            assert (source_register == 4'h3);
            assert (!unconditional_space);
            cases_checked++;
          end
        end
      end
    end

    instruction = 32'he101_1093;
    #1ps;
    assert (decode_match && unpredictable_encoding && !encoding_valid);
    assert (!execute_valid && !atomic_sequence_valid);
    cases_checked++;

    instruction = 32'hf101_2093;
    #1ps;
    assert (!decode_match && !encoding_valid && !execute_valid);
    assert (unconditional_space && !atomic_sequence_valid);
    cases_checked++;

    assert (cases_checked == 1_922);
    $display("PASS conditioned ARM atomic swap preparation (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
