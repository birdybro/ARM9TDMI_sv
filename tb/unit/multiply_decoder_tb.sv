module multiply_decoder_tb;
  import arm9_isa_pkg::*;

  logic [31:0]        instruction;
  logic               decode_match;
  logic               encoding_valid;
  logic               unpredictable_encoding;
  logic [3:0]         condition;
  arm9_multiply_kind_e multiply_kind;
  logic               set_flags;
  logic               long_multiply;
  logic               accumulate;
  logic               signed_multiply;
  logic [3:0]         destination_high_register;
  logic [3:0]         destination_low_register;
  logic [3:0]         multiplier_register;
  logic [3:0]         multiplicand_register;
  int unsigned        cases_checked;

  arm9_multiply_decoder dut (.*);

  task automatic set_short_multiply(
    input logic accumulate_value
  );
    instruction        = 32'he000_0090;
    instruction[21]    = accumulate_value;
    instruction[19:16] = 4'h1;
    instruction[15:12] = accumulate_value ? 4'h2 : 4'h0;
    instruction[11:8]  = 4'h3;
    instruction[3:0]   = 4'h4;
  endtask

  task automatic set_long_multiply(
    input logic signed_value,
    input logic accumulate_value
  );
    instruction        = 32'he080_0090;
    instruction[22]    = signed_value;
    instruction[21]    = accumulate_value;
    instruction[19:16] = 4'h1;
    instruction[15:12] = 4'h2;
    instruction[11:8]  = 4'h3;
    instruction[3:0]   = 4'h4;
  endtask

  task automatic expect_unpredictable;
    #1ps;
    assert (decode_match && unpredictable_encoding && !encoding_valid);
    cases_checked++;
  endtask

  initial begin
    instruction   = '0;
    cases_checked = 0;

    // REQ: COMMON-ARM-MULTIPLY-DECODE-001
    // Exhaust every value of bits[27:20] and bits[7:4], the complete
    // control space which distinguishes common multiply encodings.
    for (int unsigned control = 0; control < 256; control++) begin
      for (int unsigned extension = 0; extension < 16; extension++) begin
        logic expected_short;
        logic expected_long;
        arm9_multiply_kind_e expected_kind;

        instruction        = 32'he000_0000;
        instruction[27:20] = control[7:0];
        instruction[19:16] = 4'h1;
        instruction[15:12] = control[1] ? 4'h2 : 4'h0;
        instruction[11:8]  = 4'h3;
        instruction[7:4]   = extension[3:0];
        instruction[3:0]   = 4'h4;
        #1ps;

        expected_short = (control[7:2] == 6'b000000) &&
                         (extension[3:0] == 4'b1001);
        expected_long  = (control[7:3] == 5'b00001) &&
                         (extension[3:0] == 4'b1001);

        if (expected_long) begin
          if (control[2]) begin
            expected_kind = control[1] ? ARM9_MULTIPLY_SMLAL :
                                         ARM9_MULTIPLY_SMULL;
          end else begin
            expected_kind = control[1] ? ARM9_MULTIPLY_UMLAL :
                                         ARM9_MULTIPLY_UMULL;
          end
        end else begin
          expected_kind = control[1] ? ARM9_MULTIPLY_MLA :
                                       ARM9_MULTIPLY_MUL;
        end

        assert (decode_match == (expected_short || expected_long));
        assert (encoding_valid == (expected_short || expected_long));
        assert (!unpredictable_encoding);
        assert (long_multiply == expected_long);
        assert (multiply_kind == expected_kind);
        assert (set_flags == control[0]);
        assert (accumulate == control[1]);
        assert (signed_multiply == control[2]);
        assert (condition == 4'he);
        assert (destination_high_register == 4'h1);
        assert (destination_low_register == (control[1] ? 4'h2 : 4'h0));
        assert (multiplier_register == 4'h3);
        assert (multiplicand_register == 4'h4);
        cases_checked++;
      end
    end

    // REQ: COMMON-ARM-MULTIPLY-OPERANDS-001
    set_short_multiply(1'b0);
    instruction[15:12] = 4'h1;
    expect_unpredictable();

    for (int unsigned field = 0; field < 3; field++) begin
      set_short_multiply(1'b0);
      case (field)
        0: instruction[19:16] = 4'hf;
        1: instruction[11:8]  = 4'hf;
        default: instruction[3:0] = 4'hf;
      endcase
      expect_unpredictable();
    end

    for (int unsigned field = 0; field < 4; field++) begin
      set_short_multiply(1'b1);
      case (field)
        0: instruction[19:16] = 4'hf;
        1: instruction[15:12] = 4'hf;
        2: instruction[11:8]  = 4'hf;
        default: instruction[3:0] = 4'hf;
      endcase
      expect_unpredictable();
    end

    for (int unsigned field = 0; field < 4; field++) begin
      set_long_multiply(field[0], field[1]);
      case (field)
        0: instruction[19:16] = 4'hf;
        1: instruction[15:12] = 4'hf;
        2: instruction[11:8]  = 4'hf;
        default: instruction[3:0] = 4'hf;
      endcase
      expect_unpredictable();
    end

    set_long_multiply(1'b1, 1'b1);
    instruction[15:12] = instruction[19:16];
    expect_unpredictable();

    // A cond field of 0b1111 is not part of any encoding diagram whose
    // top field is "cond" in ARMv5 and is handled globally for ARMv4.
    set_short_multiply(1'b0);
    instruction[31:28] = 4'hf;
    #1ps;
    assert (!decode_match && !encoding_valid && !unpredictable_encoding);
    cases_checked++;

    assert (cases_checked == 4_110);
    $display("PASS exhaustive common ARM multiply decoder control space");
    $finish;
  end
endmodule
