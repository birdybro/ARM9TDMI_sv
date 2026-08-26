module condition_eval_tb;
  logic [3:0] condition;
  logic       flag_n;
  logic       flag_z;
  logic       flag_c;
  logic       flag_v;
  logic       condition_passed;
  logic       unconditional_space;

  arm9_condition_eval dut (.*);

  function automatic logic expected_condition(
    input logic [3:0] expected_code,
    input logic       expected_n,
    input logic       expected_z,
    input logic       expected_c,
    input logic       expected_v
  );
    case (expected_code)
      4'h0: return expected_z;
      4'h1: return !expected_z;
      4'h2: return expected_c;
      4'h3: return !expected_c;
      4'h4: return expected_n;
      4'h5: return !expected_n;
      4'h6: return expected_v;
      4'h7: return !expected_v;
      4'h8: return expected_c && !expected_z;
      4'h9: return !expected_c || expected_z;
      4'ha: return expected_n == expected_v;
      4'hb: return expected_n != expected_v;
      4'hc: return !expected_z && (expected_n == expected_v);
      4'hd: return expected_z || (expected_n != expected_v);
      4'he: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  initial begin
    // REQ: COMMON-COND-EVAL-001
    for (int unsigned flags = 0; flags < 16; flags++) begin
      {flag_n, flag_z, flag_c, flag_v} = flags[3:0];
      for (int unsigned code = 0; code < 16; code++) begin
        condition = code[3:0];
        #1ns;
        assert (condition_passed == expected_condition(
          condition, flag_n, flag_z, flag_c, flag_v
        )) else begin
          $error(
            "condition=%x NZCV=%b%b%b%b expected=%b actual=%b",
            condition,
            flag_n,
            flag_z,
            flag_c,
            flag_v,
            expected_condition(condition, flag_n, flag_z, flag_c, flag_v),
            condition_passed
          );
        end
        assert (unconditional_space == (condition == 4'hf));
      end
    end

    $display("PASS exhaustive ARM condition evaluation (256 combinations)");
    $finish;
  end
endmodule
