module data_processing_decoder_tb;
  import arm9_isa_pkg::*;

  logic [31:0]       instruction;
  logic              decode_match;
  logic              encoding_valid;
  logic              unpredictable_encoding;
  logic [3:0]        condition;
  logic              immediate_operand;
  arm9_data_opcode_e opcode;
  logic              set_flags;
  logic [3:0]        first_register;
  logic [3:0]        destination_register;
  logic [7:0]        immediate_value;
  logic [3:0]        rotate_imm;
  logic [3:0]        shift_register;
  logic [4:0]        immediate_shift_amount;
  arm9_shift_type_e  shift_type;
  logic              shift_amount_from_register;
  logic [3:0]        shifted_register;
  int unsigned       cases_checked;

  arm9_data_processing_decoder dut (.*);

  task automatic apply_and_check(
    input logic [1:0] major,
    input logic immediate,
    input logic [3:0] operation,
    input logic update_flags,
    input logic bit7,
    input logic bit4,
    input logic rn_nonzero,
    input logic rd_nonzero
  );
    logic expected_match;
    logic expected_unpredictable;
    logic extension_space;
    logic test_or_compare;
    logic unary_move;

    instruction        = 32'he000_0000;
    instruction[27:26] = major;
    instruction[25]    = immediate;
    instruction[24:21] = operation;
    instruction[20]    = update_flags;
    instruction[19:16] = rn_nonzero ? 4'ha : 4'b0000;
    instruction[15:12] = rd_nonzero ? 4'h5 : 4'b0000;
    instruction[11:8]  = 4'hb;
    instruction[7]     = bit7;
    instruction[6:5]   = ARM9_SHIFT_ASR;
    instruction[4]     = bit4;
    instruction[3:0]   = 4'hc;
    #1ps;

    test_or_compare = operation[3:2] == 2'b10;
    unary_move      = (operation == ARM9_DATA_MOV) ||
                      (operation == ARM9_DATA_MVN);
    extension_space = !immediate && bit7 && bit4;
    expected_match  = (major == 2'b00) &&
                      !extension_space &&
                      !(test_or_compare && !update_flags);
    expected_unpredictable = expected_match &&
      ((test_or_compare && rd_nonzero) || (unary_move && rn_nonzero));

    assert (decode_match == expected_match);
    assert (unpredictable_encoding == expected_unpredictable);
    assert (encoding_valid == (expected_match && !expected_unpredictable));

    assert (condition == 4'he);
    assert (immediate_operand == immediate);
    assert (opcode == arm9_data_opcode_e'(operation));
    assert (set_flags == update_flags);
    assert (first_register == (rn_nonzero ? 4'ha : 4'b0000));
    assert (destination_register == (rd_nonzero ? 4'h5 : 4'b0000));
    assert (rotate_imm == 4'hb);
    assert (shift_register == 4'hb);
    assert (immediate_shift_amount == {4'hb, bit7});
    assert (shift_type == ARM9_SHIFT_ASR);
    assert (shift_amount_from_register == (!immediate && bit4));
    assert (shifted_register == 4'hc);
    assert (immediate_value == {bit7, 2'b10, bit4, 4'hc});
    cases_checked++;
  endtask

  initial begin
    instruction  = '0;
    cases_checked = 0;

    // REQ: COMMON-ARM-DATA-DECODE-001
    // REQ: COMMON-ARM-DATA-DECODE-SBZ-001
    for (int unsigned major = 0; major < 4; major++) begin
      for (int unsigned immediate = 0; immediate < 2; immediate++) begin
        for (int unsigned operation = 0; operation < 16; operation++) begin
          for (int unsigned update_flags = 0; update_flags < 2; update_flags++) begin
            for (int unsigned bit7 = 0; bit7 < 2; bit7++) begin
              for (int unsigned bit4 = 0; bit4 < 2; bit4++) begin
                for (int unsigned rn_nonzero = 0; rn_nonzero < 2; rn_nonzero++) begin
                  for (int unsigned rd_nonzero = 0; rd_nonzero < 2; rd_nonzero++) begin
                    apply_and_check(
                      major[1:0],
                      immediate[0],
                      operation[3:0],
                      update_flags[0],
                      bit7[0],
                      bit4[0],
                      rn_nonzero[0],
                      rd_nonzero[0]
                    );
                  end
                end
              end
            end
          end
        end
      end
    end

    // Condition 0xF belongs to the unconditional instruction space.
    // REQ: COMMON-ARM-DATA-DECODE-COND-001
    instruction = 32'he280_0001;
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      instruction[31:28] = condition_case[3:0];
      #1ps;
      assert (decode_match == (condition_case != 15));
      assert (encoding_valid == (condition_case != 15));
      assert (!unpredictable_encoding);
      cases_checked++;
    end

    // REQ: COMMON-ARM-DATA-REGISTER-SHIFT-PC-001
    instruction = 32'he080_0010;
    for (int unsigned rn_case = 0; rn_case < 16; rn_case++) begin
      for (int unsigned rd_case = 0; rd_case < 16; rd_case++) begin
        for (int unsigned rs_case = 0; rs_case < 16; rs_case++) begin
          for (int unsigned rm_case = 0; rm_case < 16; rm_case++) begin
            instruction[19:16] = rn_case[3:0];
            instruction[15:12] = rd_case[3:0];
            instruction[11:8] = rs_case[3:0];
            instruction[3:0] = rm_case[3:0];
            #1ps;
            assert (decode_match);
            assert (unpredictable_encoding ==
                    ((rn_case == 15) || (rd_case == 15) ||
                     (rs_case == 15) || (rm_case == 15)));
            assert (encoding_valid == !unpredictable_encoding);
            assert (first_register == rn_case[3:0]);
            assert (destination_register == rd_case[3:0]);
            assert (shift_register == rs_case[3:0]);
            assert (shifted_register == rm_case[3:0]);
            cases_checked++;
          end
        end
      end
    end

    assert (cases_checked == 69_648);
    $display("PASS exhaustive ARM data-processing decode (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
