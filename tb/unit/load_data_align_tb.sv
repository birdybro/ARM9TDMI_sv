module load_data_align_tb;
  logic        byte_transfer;
  logic [1:0]  address_low;
  logic [31:0] aligned_word_value;
  logic [7:0]  selected_byte_value;
  logic [31:0] load_value;
  logic        unaligned_word_rotation;
  int unsigned cases_checked;

  arm9_load_data_align dut (.*);

  function automatic logic [31:0] reference_rotate(
    input logic [31:0] value,
    input logic [1:0]  low_bits
  );
    case (low_bits)
      2'b00: return value;
      2'b01: return {value[7:0], value[31:8]};
      2'b10: return {value[15:0], value[31:16]};
      2'b11: return {value[23:0], value[31:24]};
      default: return 'x;
    endcase
  endfunction

  initial begin
    cases_checked = 0;
    byte_transfer = 1'b0;
    address_low = 2'b00;
    aligned_word_value = '0;
    selected_byte_value = '0;

    // REQ: COMMON-ARM-PREV6-UNALIGNED-WORD-LOAD-001
    for (int unsigned value_case = 0; value_case < 4096;
         value_case++) begin
      for (int unsigned low_case = 0; low_case < 4; low_case++) begin
        byte_transfer = 1'b0;
        address_low = low_case[1:0];
        aligned_word_value = 32'h89ab_cdef ^
                             (32'(value_case) * 32'h0001_0201);
        selected_byte_value = value_case[7:0];
        #1ps;

        assert (load_value ==
                reference_rotate(aligned_word_value, address_low));
        assert (unaligned_word_rotation == (low_case != 0));
        cases_checked++;
      end
    end

    // REQ: COMMON-ARM-LDRB-ZERO-EXTEND-001
    for (int unsigned byte_case = 0; byte_case < 256; byte_case++) begin
      for (int unsigned low_case = 0; low_case < 4; low_case++) begin
        byte_transfer = 1'b1;
        address_low = low_case[1:0];
        aligned_word_value = 32'hffff_ffff ^ 32'(byte_case);
        selected_byte_value = byte_case[7:0];
        #1ps;

        assert (load_value == {24'b0, selected_byte_value});
        assert (!unaligned_word_rotation);
        cases_checked++;
      end
    end

    assert (cases_checked == 17_408);
    $display("PASS pre-ARMv6 word rotation and byte zero extension (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
