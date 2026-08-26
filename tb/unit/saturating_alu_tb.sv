module saturating_alu_tb;
  import arm9_isa_pkg::*;

  arm9_saturating_kind_e saturating_kind;
  logic [31:0] first_operand;
  logic [31:0] second_operand;
  logic q_in;
  logic negative_in;
  logic zero_in;
  logic carry_in;
  logic overflow_in;
  logic [31:0] result;
  logic q_set;
  logic q_out;
  logic negative_out;
  logic zero_out;
  logic carry_out;
  logic overflow_out;
  int unsigned cases_checked;

  arm9e_saturating_alu dut (.*);

  function automatic logic [31:0] boundary_value(input int unsigned index);
    case (index)
      0:  return 32'h0000_0000;
      1:  return 32'h0000_0001;
      2:  return 32'hffff_ffff;
      3:  return 32'h7fff_ffff;
      4:  return 32'h7fff_fffe;
      5:  return 32'h8000_0000;
      6:  return 32'h8000_0001;
      7:  return 32'h4000_0000;
      8:  return 32'h4000_0001;
      9:  return 32'h3fff_ffff;
      10: return 32'hc000_0000;
      11: return 32'hbfff_ffff;
      12: return 32'hc000_0001;
      13: return 32'h5555_5555;
      14: return 32'haaaa_aaaa;
      default: return 32'h1234_5678;
    endcase
  endfunction

  function automatic logic [31:0] lfsr_next(input logic [31:0] value);
    return {value[30:0], value[31] ^ value[21] ^ value[1] ^ value[0]};
  endfunction

  task automatic check_case;
    logic signed [63:0] first_signed;
    logic signed [63:0] second_signed;
    logic signed [63:0] doubled_signed;
    logic signed [63:0] stage_operand;
    logic signed [63:0] result_signed;
    logic expected_double_saturation;
    logic expected_result_saturation;
    logic [31:0] expected_result;
    begin
      first_signed = $signed({{32{first_operand[31]}}, first_operand});
      second_signed = $signed({{32{second_operand[31]}}, second_operand});
      doubled_signed = second_signed * 64'sd2;
      expected_double_saturation = 1'b0;
      if (saturating_kind[1]) begin
        if (doubled_signed > 64'sh0000_0000_7fff_ffff) begin
          stage_operand = 64'sh0000_0000_7fff_ffff;
          expected_double_saturation = 1'b1;
        end else if (doubled_signed < -64'sh0000_0000_8000_0000) begin
          stage_operand = -64'sh0000_0000_8000_0000;
          expected_double_saturation = 1'b1;
        end else begin
          stage_operand = doubled_signed;
        end
      end else begin
        stage_operand = second_signed;
      end

      if (saturating_kind[0]) begin
        result_signed = first_signed - stage_operand;
      end else begin
        result_signed = first_signed + stage_operand;
      end
      expected_result_saturation = 1'b0;
      if (result_signed > 64'sh0000_0000_7fff_ffff) begin
        expected_result = 32'h7fff_ffff;
        expected_result_saturation = 1'b1;
      end else if (result_signed < -64'sh0000_0000_8000_0000) begin
        expected_result = 32'h8000_0000;
        expected_result_saturation = 1'b1;
      end else begin
        expected_result = result_signed[31:0];
      end

      #1ps;
      assert (result == expected_result);
      assert (q_set ==
              (expected_double_saturation || expected_result_saturation));
      assert (q_out == (q_in || q_set));
      assert (negative_out == negative_in);
      assert (zero_out == zero_in);
      assert (carry_out == carry_in);
      assert (overflow_out == overflow_in);
      cases_checked++;
    end
  endtask

  initial begin
    logic [31:0] lfsr;

    saturating_kind = ARM9_SATURATING_QADD;
    first_operand   = '0;
    second_operand  = '0;
    q_in            = 1'b0;
    negative_in     = 1'b0;
    zero_in         = 1'b0;
    carry_in        = 1'b0;
    overflow_in     = 1'b0;
    cases_checked   = 0;

    // REQ: ARM946ES-ARM-QADD-ARITHMETIC-001
    // REQ: ARM946ES-ARM-QADD-FLAGS-001
    for (int unsigned kind = 0; kind < 4; kind++) begin
      saturating_kind = arm9_saturating_kind_e'(kind[1:0]);
      for (int unsigned first_index = 0; first_index < 16;
           first_index++) begin
        for (int unsigned second_index = 0; second_index < 16;
             second_index++) begin
          first_operand  = boundary_value(first_index);
          second_operand = boundary_value(second_index);
          for (int unsigned status = 0; status < 32; status++) begin
            q_in        = status[4];
            negative_in = status[3];
            zero_in     = status[2];
            carry_in    = status[1];
            overflow_in = status[0];
            check_case();
          end
        end
      end
    end

    lfsr = 32'h6d2b_79f5;
    for (int unsigned kind = 0; kind < 4; kind++) begin
      saturating_kind = arm9_saturating_kind_e'(kind[1:0]);
      for (int unsigned random_case = 0; random_case < 4096;
           random_case++) begin
        lfsr = lfsr_next(lfsr);
        first_operand = lfsr;
        lfsr = lfsr_next(lfsr);
        second_operand = lfsr;
        lfsr = lfsr_next(lfsr);
        q_in        = lfsr[4];
        negative_in = lfsr[3];
        zero_in     = lfsr[2];
        carry_in    = lfsr[1];
        overflow_in = lfsr[0];
        check_case();
      end
    end

    assert (cases_checked == 49_152);
    $display("PASS ARM9E-S saturating arithmetic (%0d boundary/random cases)",
             cases_checked);
    $finish;
  end
endmodule
