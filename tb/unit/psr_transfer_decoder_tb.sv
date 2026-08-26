module psr_transfer_decoder_tb;
  logic [31:0] instruction;
  logic decode_match;
  logic encoding_valid;
  logic unpredictable_encoding;
  logic [3:0] condition;
  logic mrs_operation;
  logic msr_operation;
  logic immediate_operand;
  logic spsr_select;
  logic [3:0] field_mask;
  logic [3:0] destination_register;
  logic [3:0] source_register;
  logic [3:0] rotate_imm;
  logic [7:0] immediate_value;
  int unsigned cases_checked;

  arm9_psr_transfer_decoder dut (.*);

  initial begin
    instruction = 32'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-MRS-DECODE-001
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned spsr_case = 0; spsr_case < 2; spsr_case++) begin
        for (int unsigned register_case = 0; register_case < 16;
             register_case++) begin
          instruction = {condition_case[3:0], 5'b00010,
                         spsr_case[0], 2'b00, 4'hf,
                         register_case[3:0], 12'b0};
          #1ps;

          assert (condition == condition_case[3:0]);
          assert (decode_match == (condition_case != 15));
          assert (mrs_operation == (condition_case != 15));
          assert (!msr_operation && !immediate_operand);
          assert (spsr_select == spsr_case[0]);
          assert (destination_register == register_case[3:0]);
          assert (unpredictable_encoding ==
                  ((condition_case != 15) && (register_case == 15)));
          assert (encoding_valid ==
                  ((condition_case != 15) && (register_case != 15)));
          cases_checked++;
        end
      end
    end

    // REQ: COMMON-ARM-MSR-DECODE-001
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned spsr_case = 0; spsr_case < 2; spsr_case++) begin
        for (int unsigned mask_case = 0; mask_case < 16; mask_case++) begin
          for (int unsigned register_case = 0; register_case < 16;
               register_case++) begin
            instruction = {condition_case[3:0], 5'b00010,
                           spsr_case[0], 2'b10, mask_case[3:0],
                           12'hf00, register_case[3:0]};
            #1ps;

            assert (condition == condition_case[3:0]);
            assert (decode_match == (condition_case != 15));
            assert (!mrs_operation);
            assert (msr_operation == (condition_case != 15));
            assert (!immediate_operand);
            assert (spsr_select == spsr_case[0]);
            assert (field_mask == mask_case[3:0]);
            assert (source_register == register_case[3:0]);
            assert (!unpredictable_encoding);
            assert (encoding_valid == (condition_case != 15));
            cases_checked++;
          end
        end
      end
    end

    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned spsr_case = 0; spsr_case < 2; spsr_case++) begin
        for (int unsigned mask_case = 0; mask_case < 16; mask_case++) begin
          for (int unsigned immediate_case = 0; immediate_case < 4096;
               immediate_case++) begin
            instruction = {condition_case[3:0], 5'b00110,
                           spsr_case[0], 2'b10, mask_case[3:0],
                           4'hf, immediate_case[11:0]};
            #1ps;

            assert (condition == condition_case[3:0]);
            assert (decode_match == (condition_case != 15));
            assert (!mrs_operation);
            assert (msr_operation == (condition_case != 15));
            assert (immediate_operand == (condition_case != 15));
            assert (spsr_select == spsr_case[0]);
            assert (field_mask == mask_case[3:0]);
            assert (rotate_imm == immediate_case[11:8]);
            assert (immediate_value == immediate_case[7:0]);
            assert (!unpredictable_encoding);
            assert (encoding_valid == (condition_case != 15));
            cases_checked++;
          end
        end
      end
    end

    instruction = 32'he10f_0001;
    #1ps;
    assert (!decode_match && !encoding_valid);
    instruction = 32'he129_f010;
    #1ps;
    assert (!decode_match && !encoding_valid);
    instruction = 32'he329_0f00;
    #1ps;
    assert (!decode_match && !encoding_valid);

    assert (cases_checked == 2_105_856);
    $display("PASS exhaustive ARM MRS/MSR decoder (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
