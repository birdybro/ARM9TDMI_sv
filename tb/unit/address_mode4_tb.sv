module address_mode4_tb;
  logic [31:0] instruction;
  logic [31:0] base_value;
  logic        decode_match;
  logic        encoding_valid;
  logic        unpredictable_encoding;
  logic [3:0]  condition;
  logic        pre_index;
  logic        increment;
  logic        psr_or_user;
  logic        writeback;
  logic        load;
  logic [3:0]  base_register;
  logic [15:0] register_list;
  logic [4:0]  register_count;
  logic [3:0]  first_register;
  logic [3:0]  last_register;
  logic        load_pc;
  logic        user_bank_transfer;
  logic        restore_cpsr;
  logic        privileged_mode_required;
  logic        spsr_required;
  logic        base_in_register_list;
  logic        load_base_writeback_unpredictable;
  logic        store_base_uses_original_value;
  logic        store_base_value_unpredictable;
  logic        unaligned_base;
  logic [31:0] start_address;
  logic [31:0] end_address;
  logic [31:0] writeback_address;
  int unsigned cases_checked;

  arm9_address_mode4 dut (.*);

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

  task automatic check_current;
    logic [4:0] expected_count;
    logic expected_load_pc;
    logic expected_restore;
    logic expected_user_bank;
    logic expected_unpredictable;
    logic expected_base_in_list;
    logic expected_lower_selected;
    logic [31:0] expected_aligned_base;
    logic [31:0] expected_bytes;
    logic [31:0] expected_start;
    logic [31:0] expected_end;
    logic [31:0] expected_writeback;

    expected_count = bit_count(instruction[15:0]);
    expected_load_pc = instruction[20] && instruction[15];
    expected_restore = instruction[22] && expected_load_pc;
    expected_user_bank = instruction[22] && !expected_load_pc;
    expected_unpredictable = (instruction[19:16] == 4'hf) ||
                             (expected_count == 5'd0) ||
                             (expected_user_bank && instruction[21]);
    expected_base_in_list = instruction[{1'b0, instruction[19:16]}];
    expected_lower_selected = 1'b0;
    for (int unsigned index = 0; index < 16; index++) begin
      if ((index < int'(instruction[19:16])) && instruction[index]) begin
        expected_lower_selected = 1'b1;
      end
    end
    expected_aligned_base = {base_value[31:2], 2'b00};
    expected_bytes = {25'b0, expected_count, 2'b00};
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
    assert (condition == instruction[31:28]);
    assert (pre_index == instruction[24]);
    assert (increment == instruction[23]);
    assert (psr_or_user == instruction[22]);
    assert (writeback == instruction[21]);
    assert (load == instruction[20]);
    assert (base_register == instruction[19:16]);
    assert (register_list == instruction[15:0]);
    assert (register_count == expected_count);
    assert (first_register == first_set(instruction[15:0]));
    assert (last_register == last_set(instruction[15:0]));
    assert (load_pc == expected_load_pc);
    assert (restore_cpsr == expected_restore);
    assert (user_bank_transfer == expected_user_bank);
    assert (privileged_mode_required == instruction[22]);
    assert (spsr_required == expected_restore);
    assert (unpredictable_encoding == expected_unpredictable);
    assert (encoding_valid == !expected_unpredictable);
    assert (base_in_register_list == expected_base_in_list);
    assert (load_base_writeback_unpredictable ==
            (!expected_unpredictable && instruction[20] &&
             instruction[21] && expected_base_in_list));
    assert (store_base_uses_original_value ==
            (!expected_unpredictable && !instruction[20] &&
             instruction[21] && expected_base_in_list &&
             !expected_lower_selected));
    assert (store_base_value_unpredictable ==
            (!expected_unpredictable && !instruction[20] &&
             instruction[21] && expected_base_in_list &&
             expected_lower_selected));
    assert (unaligned_base == (base_value[1:0] != 2'b00));
    assert (start_address == expected_start);
    assert (end_address == expected_end);
    assert (writeback_address == expected_writeback);
    cases_checked++;
  endtask

  initial begin
    instruction = 32'b0;
    base_value = 32'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-ADDRESS-MODE4-DECODE-001
    // REQ: COMMON-ARM-ADDRESS-MODE4-RANGE-001
    // REQ: COMMON-ARM-BLOCK-BASE-COLLISION-001
    for (int unsigned control = 0; control < 32; control++) begin
      for (int unsigned base = 0; base < 16; base++) begin
        for (int unsigned list = 0; list < 65536; list++) begin
          instruction = {4'he, 3'b100, control[4:0], base[3:0],
                         list[15:0]};
          base_value = 32'h8000_0000 ^ (32'(list) << 2) ^
                       32'(control[1:0]);
          check_current();
        end
      end
    end

    instruction = {4'hf, 3'b100, 25'b0};
    #1ps;
    assert (!decode_match && !encoding_valid && !unpredictable_encoding);
    instruction = {4'he, 3'b101, 25'b0};
    #1ps;
    assert (!decode_match && !encoding_valid && !unpredictable_encoding);

    assert (cases_checked == 33_554_432);
    $display("PASS exhaustive ARM Addressing Mode 4 (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
