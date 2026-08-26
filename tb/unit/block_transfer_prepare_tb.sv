module block_transfer_prepare_tb;
  import arm9_arch_pkg::*;

  logic [31:0] instruction;
  logic [31:0] base_value;
  arm9_mode_e current_mode;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;
  logic decode_match;
  logic encoding_valid;
  logic unpredictable_encoding;
  logic condition_passed;
  logic unconditional_space;
  logic unpredictable_operation;
  logic execute_valid;
  logic transfer_load;
  logic transfer_store;
  logic [3:0] base_register;
  logic [15:0] register_list;
  logic [4:0] register_count;
  logic [3:0] first_register;
  logic [3:0] last_register;
  logic memory_sequence_valid;
  logic [4:0] memory_word_count;
  logic [31:0] first_word_address;
  logic [31:0] last_word_address;
  logic addresses_ascending;
  logic unaligned_base;
  logic transfer_user_bank;
  logic pc_load_pending;
  logic restore_cpsr_pending;
  logic base_writeback_pending;
  logic [31:0] base_writeback_value;
  logic base_writeback_value_unpredictable;
  logic store_base_uses_original_value;
  logic store_base_value_unpredictable;
  int unsigned cases_checked;

  arm9_block_transfer_prepare dut (.*);

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

  function automatic logic [15:0] list_for_case(input int unsigned value);
    case (value)
      0: return 16'h0001;
      1: return 16'h0003;
      2: return 16'h8000;
      3: return 16'h8001;
      4: return 16'h00f0;
      5: return 16'h5555;
      6: return 16'haaaa;
      7: return 16'hffff;
      8: return 16'h0100;
      9: return 16'h0180;
      10: return 16'h0081;
      default: return 16'h7fff;
    endcase
  endfunction

  function automatic logic [4:0] bit_count(input logic [15:0] value);
    logic [4:0] count;
    count = 5'b0;
    for (int unsigned index = 0; index < 16; index++) begin
      count += 5'(value[index]);
    end
    return count;
  endfunction

  function automatic logic [3:0] first_set(input logic [15:0] value);
    for (int unsigned index = 0; index < 16; index++) begin
      if (value[index]) begin
        return 4'(index);
      end
    end
    return 4'b0;
  endfunction

  function automatic logic [3:0] last_set(input logic [15:0] value);
    logic [3:0] result;
    result = 4'b0;
    for (int unsigned index = 0; index < 16; index++) begin
      if (value[index]) begin
        result = 4'(index);
      end
    end
    return result;
  endfunction

  initial begin
    logic expected_condition;
    logic expected_user_bank;
    logic expected_restore;
    logic expected_runtime_unpredictable;
    logic expected_execute;
    logic expected_base_in_list;
    logic expected_lower_selected;
    logic [4:0] expected_count;
    logic [31:0] expected_bytes;
    logic [31:0] expected_aligned_base;
    logic [31:0] expected_start;
    logic [31:0] expected_end;
    logic [31:0] expected_writeback;

    instruction = 32'he890_0001;
    base_value = 32'h1000_0000;
    current_mode = ARM9_MODE_USER;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-BLOCK-PREPARE-001
    // REQ: COMMON-ARM-BLOCK-PRIVILEGE-001
    for (int unsigned control = 0; control < 32; control++) begin
      for (int unsigned condition_case = 0; condition_case < 15;
           condition_case++) begin
        for (int unsigned flags = 0; flags < 16; flags++) begin
          for (int unsigned mode_case = 0; mode_case < 7; mode_case++) begin
            for (int unsigned list_case = 0; list_case < 12;
                 list_case++) begin
              instruction = {condition_case[3:0], 3'b100,
                             control[4:0], 4'h8,
                             list_for_case(list_case)};
              base_value = 32'h8000_0000 | (32'(list_case) << 8) |
                           32'(control[1:0]);
              current_mode = mode_for_case(mode_case);
              negative = flags[3];
              zero = flags[2];
              carry = flags[1];
              overflow = flags[0];

              expected_condition = reference_condition(
                condition_case[3:0], negative, zero, carry, overflow
              );
              expected_user_bank = instruction[22] &&
                !(instruction[20] && instruction[15]);
              expected_restore = instruction[22] && instruction[20] &&
                                 instruction[15];
              expected_runtime_unpredictable = expected_condition &&
                instruction[22] && !mode_has_spsr(current_mode);
              expected_execute = expected_condition &&
                                 !expected_runtime_unpredictable &&
                                 !(expected_user_bank && instruction[21]);
              expected_count = bit_count(instruction[15:0]);
              expected_bytes = {25'b0, expected_count, 2'b00};
              expected_base_in_list = instruction[8];
              expected_lower_selected = |instruction[7:0];
              expected_aligned_base = {base_value[31:2], 2'b00};
              if (instruction[23]) begin
                expected_start = expected_aligned_base +
                                 (instruction[24] ? 32'd4 : 32'd0);
                expected_end = expected_aligned_base + expected_bytes -
                               (instruction[24] ? 32'd0 : 32'd4);
                expected_writeback = base_value + expected_bytes;
              end else begin
                expected_start = expected_aligned_base - expected_bytes +
                                 (instruction[24] ? 32'd0 : 32'd4);
                expected_end = expected_aligned_base -
                               (instruction[24] ? 32'd4 : 32'd0);
                expected_writeback = base_value - expected_bytes;
              end
              #1ps;

              assert (decode_match);
              assert (encoding_valid ==
                      !(expected_user_bank && instruction[21]));
              assert (unpredictable_encoding ==
                      (expected_user_bank && instruction[21]));
              assert (condition_passed == expected_condition);
              assert (!unconditional_space);
              assert (unpredictable_operation ==
                      (expected_runtime_unpredictable &&
                       encoding_valid));
              assert (execute_valid == expected_execute);
              assert (transfer_load == instruction[20]);
              assert (transfer_store == !instruction[20]);
              assert (base_register == 4'h8);
              assert (register_list == instruction[15:0]);
              assert (register_count == expected_count);
              assert (first_register == first_set(instruction[15:0]));
              assert (last_register == last_set(instruction[15:0]));
              assert (memory_sequence_valid == expected_execute);
              assert (memory_word_count ==
                      (expected_execute ? expected_count : 5'b0));
              assert (first_word_address == expected_start);
              assert (last_word_address == expected_end);
              assert (addresses_ascending == expected_execute);
              assert (unaligned_base == (base_value[1:0] != 2'b00));
              assert (transfer_user_bank ==
                      (expected_execute && expected_user_bank));
              assert (pc_load_pending ==
                      (expected_execute && instruction[20] &&
                       instruction[15]));
              assert (restore_cpsr_pending ==
                      (expected_execute && expected_restore));
              assert (base_writeback_pending ==
                      (expected_execute && instruction[21]));
              assert (base_writeback_value == expected_writeback);
              assert (base_writeback_value_unpredictable ==
                      (expected_execute && instruction[20] &&
                       instruction[21] && expected_base_in_list));
              assert (store_base_uses_original_value ==
                      (expected_execute && !instruction[20] &&
                       instruction[21] && expected_base_in_list &&
                       !expected_lower_selected));
              assert (store_base_value_unpredictable ==
                      (expected_execute && !instruction[20] &&
                       instruction[21] && expected_base_in_list &&
                       expected_lower_selected));
              cases_checked++;
            end
          end
        end
      end
    end

    instruction = 32'he89f_0001;
    #1ps;
    assert (decode_match && !encoding_valid && unpredictable_encoding);
    instruction = 32'he898_0000;
    #1ps;
    assert (decode_match && !encoding_valid && unpredictable_encoding);

    assert (cases_checked == 645_120);
    $display("PASS condition-gated ARM block-transfer preparation (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
