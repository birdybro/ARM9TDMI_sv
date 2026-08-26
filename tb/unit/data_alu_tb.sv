module data_alu_tb;
  import arm9_isa_pkg::*;

  typedef struct packed {
    logic [31:0] result;
    logic        writes_result;
    logic        negative;
    logic        zero;
    logic        carry;
    logic        overflow;
  } expected_alu_t;

  arm9_data_opcode_e opcode;
  logic [31:0]       first_operand;
  logic [31:0]       shifter_operand;
  logic              carry_in;
  logic              overflow_in;
  logic              shifter_carry_out;
  logic [31:0]       result;
  logic              writes_result;
  logic              negative_out;
  logic              zero_out;
  logic              carry_out;
  logic              overflow_out;
  logic [31:0]       boundary_values [0:11];
  int unsigned       cases_checked;

  arm9_data_alu dut (.*);

  function automatic expected_alu_t reference_alu(
    input arm9_data_opcode_e reference_opcode,
    input logic [31:0] first,
    input logic [31:0] second,
    input logic reference_carry,
    input logic reference_overflow,
    input logic reference_shifter_carry
  );
    expected_alu_t expected;
    logic [32:0] wide;

    expected = '0;
    expected.writes_result = 1'b1;
    expected.carry          = reference_shifter_carry;
    expected.overflow       = reference_overflow;
    wide                    = '0;

    case (reference_opcode)
      ARM9_DATA_AND: expected.result = first & second;
      ARM9_DATA_EOR: expected.result = first ^ second;
      ARM9_DATA_SUB,
      ARM9_DATA_CMP: begin
        wide = {1'b0, first} + {1'b0, ~second} + 33'd1;
        expected.result   = wide[31:0];
        expected.carry    = wide[32];
        expected.overflow = (first[31] ^ second[31]) &
                            (expected.result[31] ^ first[31]);
      end
      ARM9_DATA_RSB: begin
        wide = {1'b0, second} + {1'b0, ~first} + 33'd1;
        expected.result   = wide[31:0];
        expected.carry    = wide[32];
        expected.overflow = (second[31] ^ first[31]) &
                            (expected.result[31] ^ second[31]);
      end
      ARM9_DATA_ADD,
      ARM9_DATA_CMN: begin
        wide = {1'b0, first} + {1'b0, second};
        expected.result   = wide[31:0];
        expected.carry    = wide[32];
        expected.overflow = ~(first[31] ^ second[31]) &
                            (expected.result[31] ^ first[31]);
      end
      ARM9_DATA_ADC: begin
        wide = {1'b0, first} + {1'b0, second} +
               {{32{1'b0}}, reference_carry};
        expected.result   = wide[31:0];
        expected.carry    = wide[32];
        expected.overflow = ~(first[31] ^ second[31]) &
                            (expected.result[31] ^ first[31]);
      end
      ARM9_DATA_SBC: begin
        wide = {1'b0, first} + {1'b0, ~second} +
               {{32{1'b0}}, reference_carry};
        expected.result   = wide[31:0];
        expected.carry    = wide[32];
        expected.overflow = (first[31] ^ second[31]) &
                            (expected.result[31] ^ first[31]);
      end
      ARM9_DATA_RSC: begin
        wide = {1'b0, second} + {1'b0, ~first} +
               {{32{1'b0}}, reference_carry};
        expected.result   = wide[31:0];
        expected.carry    = wide[32];
        expected.overflow = (second[31] ^ first[31]) &
                            (expected.result[31] ^ second[31]);
      end
      ARM9_DATA_TST: expected.result = first & second;
      ARM9_DATA_TEQ: expected.result = first ^ second;
      ARM9_DATA_ORR: expected.result = first | second;
      ARM9_DATA_MOV: expected.result = second;
      ARM9_DATA_BIC: expected.result = first & ~second;
      ARM9_DATA_MVN: expected.result = ~second;
      default: expected = 'x;
    endcase

    if ((reference_opcode == ARM9_DATA_TST) ||
        (reference_opcode == ARM9_DATA_TEQ) ||
        (reference_opcode == ARM9_DATA_CMP) ||
        (reference_opcode == ARM9_DATA_CMN)) begin
      expected.writes_result = 1'b0;
    end
    expected.negative = expected.result[31];
    expected.zero     = (expected.result == 32'b0);
    return expected;
  endfunction

  task automatic apply_and_check(
    input arm9_data_opcode_e test_opcode,
    input logic [31:0] test_first,
    input logic [31:0] test_second,
    input logic test_carry,
    input logic test_overflow,
    input logic test_shifter_carry
  );
    expected_alu_t expected;

    opcode            = test_opcode;
    first_operand     = test_first;
    shifter_operand   = test_second;
    carry_in          = test_carry;
    overflow_in       = test_overflow;
    shifter_carry_out = test_shifter_carry;
    #1ps;
    expected = reference_alu(
      test_opcode,
      test_first,
      test_second,
      test_carry,
      test_overflow,
      test_shifter_carry
    );
    assert ({
      result,
      writes_result,
      negative_out,
      zero_out,
      carry_out,
      overflow_out
    } == expected) else begin
      $error(
        "opcode=%x first=%08x second=%08x cin=%0d vin=%0d sc=%0d expected=%010x actual=%08x%0d%0d%0d%0d%0d",
        test_opcode,
        test_first,
        test_second,
        test_carry,
        test_overflow,
        test_shifter_carry,
        expected,
        result,
        writes_result,
        negative_out,
        zero_out,
        carry_out,
        overflow_out
      );
    end
    cases_checked++;
  endtask

  initial begin
    boundary_values[0]  = 32'h0000_0000;
    boundary_values[1]  = 32'h0000_0001;
    boundary_values[2]  = 32'h0000_0002;
    boundary_values[3]  = 32'h7fff_fffe;
    boundary_values[4]  = 32'h7fff_ffff;
    boundary_values[5]  = 32'h8000_0000;
    boundary_values[6]  = 32'h8000_0001;
    boundary_values[7]  = 32'hffff_fffe;
    boundary_values[8]  = 32'hffff_ffff;
    boundary_values[9]  = 32'ha5a5_5a5a;
    boundary_values[10] = 32'h5555_aaaa;
    boundary_values[11] = 32'h0123_4567;
    cases_checked       = 0;

    // REQ: COMMON-ARM-DATA-ALU-001
    // REQ: COMMON-ARM-DATA-FLAGS-001
    for (int unsigned kind = 0; kind < 16; kind++) begin
      for (int unsigned first = 0; first < 256; first++) begin
        for (int unsigned second = 0; second < 256; second++) begin
          for (int unsigned carry = 0; carry < 2; carry++) begin
            apply_and_check(
              arm9_data_opcode_e'(kind[3:0]),
              {24'b0, first[7:0]},
              {24'b0, second[7:0]},
              carry[0],
              carry[0],
              first[0] ^ second[0] ^ carry[0]
            );
          end
        end
      end
    end

    for (int unsigned kind = 0; kind < 16; kind++) begin
      for (int unsigned first = 0; first < 12; first++) begin
        for (int unsigned second = 0; second < 12; second++) begin
          for (int unsigned carry = 0; carry < 2; carry++) begin
            apply_and_check(
              arm9_data_opcode_e'(kind[3:0]),
              boundary_values[first],
              boundary_values[second],
              carry[0],
              ~carry[0],
              carry[0]
            );
          end
        end
      end
    end

    assert (cases_checked == 2_101_760);
    $display("PASS all 16 ARM data ALU operations (%0d cases)", cases_checked);
    $finish;
  end
endmodule
