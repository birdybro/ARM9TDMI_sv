module arm9_barrel_shifter (
  input  logic [31:0]                   value,
  input  arm9_isa_pkg::arm9_shift_type_e shift_type,
  input  logic [7:0]                    shift_amount,
  input  logic                          amount_from_register,
  input  logic                          carry_in,
  output logic [31:0]                   result,
  output logic                          carry_out
);
  import arm9_isa_pkg::*;

  int unsigned shift_count;

  always_comb begin
    result      = value;
    carry_out   = carry_in;
    shift_count = {24'b0, shift_amount};

    if (amount_from_register) begin
      case (shift_type)
        ARM9_SHIFT_LSL: begin
          if (shift_count == 0) begin
            result    = value;
            carry_out = carry_in;
          end else if (shift_count < 32) begin
            result    = value << shift_count;
            carry_out = value[32 - shift_count];
          end else if (shift_count == 32) begin
            result    = '0;
            carry_out = value[0];
          end else begin
            result    = '0;
            carry_out = 1'b0;
          end
        end
        ARM9_SHIFT_LSR: begin
          if (shift_count == 0) begin
            result    = value;
            carry_out = carry_in;
          end else if (shift_count < 32) begin
            result    = value >> shift_count;
            carry_out = value[shift_count - 1];
          end else if (shift_count == 32) begin
            result    = '0;
            carry_out = value[31];
          end else begin
            result    = '0;
            carry_out = 1'b0;
          end
        end
        ARM9_SHIFT_ASR: begin
          if (shift_count == 0) begin
            result    = value;
            carry_out = carry_in;
          end else if (shift_count < 32) begin
            result    = $unsigned($signed(value) >>> shift_count);
            carry_out = value[shift_count - 1];
          end else begin
            result    = {32{value[31]}};
            carry_out = value[31];
          end
        end
        ARM9_SHIFT_ROR: begin
          if (shift_count == 0) begin
            result    = value;
            carry_out = carry_in;
          end else if (shift_amount[4:0] == 0) begin
            result    = value;
            carry_out = value[31];
          end else begin
            shift_count = {27'b0, shift_amount[4:0]};
            result      = (value >> shift_count) |
                          (value << (32 - shift_count));
            carry_out   = value[shift_count - 1];
          end
        end
        default: begin
          result    = 'x;
          carry_out = 1'bx;
        end
      endcase
    end else begin
      case (shift_type)
        ARM9_SHIFT_LSL: begin
          if (shift_count != 0) begin
            result    = value << shift_count;
            carry_out = value[32 - shift_count];
          end
        end
        ARM9_SHIFT_LSR: begin
          if (shift_count == 0) begin
            result    = '0;
            carry_out = value[31];
          end else begin
            result    = value >> shift_count;
            carry_out = value[shift_count - 1];
          end
        end
        ARM9_SHIFT_ASR: begin
          if (shift_count == 0) begin
            result    = {32{value[31]}};
            carry_out = value[31];
          end else begin
            result    = $unsigned($signed(value) >>> shift_count);
            carry_out = value[shift_count - 1];
          end
        end
        ARM9_SHIFT_ROR: begin
          if (shift_count == 0) begin
            result    = {carry_in, value[31:1]};
            carry_out = value[0];
          end else begin
            result    = (value >> shift_count) |
                        (value << (32 - shift_count));
            carry_out = value[shift_count - 1];
          end
        end
        default: begin
          result    = 'x;
          carry_out = 1'bx;
        end
      endcase
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    if (!amount_from_register) begin
      assert (shift_amount <= 8'd31);
    end
  end
`endif
endmodule
