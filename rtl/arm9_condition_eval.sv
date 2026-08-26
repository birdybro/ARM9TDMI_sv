module arm9_condition_eval (
  input  logic [3:0] condition,
  input  logic       flag_n,
  input  logic       flag_z,
  input  logic       flag_c,
  input  logic       flag_v,
  output logic       condition_passed,
  output logic       unconditional_space
);
  always_comb begin
    unconditional_space = (condition == 4'b1111);

    unique case (condition)
      4'b0000: condition_passed = flag_z;
      4'b0001: condition_passed = !flag_z;
      4'b0010: condition_passed = flag_c;
      4'b0011: condition_passed = !flag_c;
      4'b0100: condition_passed = flag_n;
      4'b0101: condition_passed = !flag_n;
      4'b0110: condition_passed = flag_v;
      4'b0111: condition_passed = !flag_v;
      4'b1000: condition_passed = flag_c && !flag_z;
      4'b1001: condition_passed = !flag_c || flag_z;
      4'b1010: condition_passed = (flag_n == flag_v);
      4'b1011: condition_passed = (flag_n != flag_v);
      4'b1100: condition_passed = !flag_z && (flag_n == flag_v);
      4'b1101: condition_passed = flag_z || (flag_n != flag_v);
      4'b1110: condition_passed = 1'b1;
      default: condition_passed = 1'b0;
    endcase
  end
endmodule
