module swap_decoder_tb;
  logic [31:0] instruction;
  logic        decode_match;
  logic        encoding_valid;
  logic        unpredictable_encoding;
  logic [3:0]  condition;
  logic        byte_swap;
  logic [3:0]  base_register;
  logic [3:0]  destination_register;
  logic [3:0]  source_register;
  int unsigned cases_checked;

  arm9_swap_decoder dut (.*);

  initial begin
    logic expected_decode;
    logic expected_unpredictable;

    instruction = 32'he101_2093;
    cases_checked = 0;

    // REQ: COMMON-ARM-SWP-DECODE-001
    for (int unsigned condition_case = 0; condition_case < 16;
         condition_case++) begin
      for (int unsigned upper_control = 0; upper_control < 256;
           upper_control++) begin
        for (int unsigned low_control = 0; low_control < 16;
             low_control++) begin
          instruction = '0;
          instruction[31:28] = condition_case[3:0];
          instruction[27:20] = upper_control[7:0];
          instruction[19:16] = 4'h1;
          instruction[15:12] = 4'h2;
          instruction[7:4] = low_control[3:0];
          instruction[3:0] = 4'h3;
          expected_decode = (condition_case != 15) &&
            (upper_control[7:3] == 5'b00010) &&
            (upper_control[1:0] == 2'b00) &&
            (low_control[3:0] == 4'b1001);
          #1ps;
          assert (decode_match == expected_decode);
          assert (condition == condition_case[3:0]);
          assert (byte_swap == upper_control[2]);
          cases_checked++;
        end
      end
    end

    // REQ: COMMON-ARM-SWP-CONSTRAINTS-001
    for (int unsigned byte_case = 0; byte_case < 2; byte_case++) begin
      for (int unsigned reserved_case = 0; reserved_case < 2;
           reserved_case++) begin
        for (int unsigned rn = 0; rn < 16; rn++) begin
          for (int unsigned rd = 0; rd < 16; rd++) begin
            for (int unsigned rm = 0; rm < 16; rm++) begin
              instruction = 32'he101_2093;
              instruction[22] = byte_case[0];
              instruction[19:16] = rn[3:0];
              instruction[15:12] = rd[3:0];
              instruction[11:8] = reserved_case[0] ? 4'ha : 4'h0;
              instruction[3:0] = rm[3:0];
              expected_unpredictable = reserved_case[0] ||
                (rn == 15) || (rd == 15) || (rm == 15) ||
                (rn == rd) || (rn == rm);
              #1ps;
              assert (decode_match);
              assert (unpredictable_encoding == expected_unpredictable);
              assert (encoding_valid == !expected_unpredictable);
              assert (byte_swap == byte_case[0]);
              assert (base_register == rn[3:0]);
              assert (destination_register == rd[3:0]);
              assert (source_register == rm[3:0]);
              cases_checked++;
            end
          end
        end
      end
    end

    assert (cases_checked == 81_920);
    $display("PASS exhaustive common ARM SWP/SWPB decode (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
