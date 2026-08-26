module arm9_misc_load_data_format (
  input  arm9_isa_pkg::arm9_misc_transfer_kind_e transfer_kind,
  input  logic [7:0]                             selected_byte_value,
  input  logic [15:0]                            selected_halfword_value,
  output logic                                   format_valid,
  output logic [31:0]                            load_value
);
  import arm9_isa_pkg::*;

  always_comb begin
    format_valid = 1'b1;
    case (transfer_kind)
      ARM9_MISC_TRANSFER_LDRH: begin
        load_value = {16'b0, selected_halfword_value};
      end
      ARM9_MISC_TRANSFER_LDRSB: begin
        load_value = {{24{selected_byte_value[7]}}, selected_byte_value};
      end
      ARM9_MISC_TRANSFER_LDRSH: begin
        load_value = {{16{selected_halfword_value[15]}},
                      selected_halfword_value};
      end
      default: begin
        format_valid = 1'b0;
        load_value = '0;
      end
    endcase
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (format_valid == (transfer_kind != ARM9_MISC_TRANSFER_STRH));
    if (!format_valid) begin
      assert (load_value == 32'b0);
    end
  end
`endif
endmodule
