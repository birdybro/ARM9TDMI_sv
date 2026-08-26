module misc_transfer_prepare_tb;
  import arm9_isa_pkg::*;

  logic [31:0]                  instruction;
  logic [31:0]                  base_value;
  logic [31:0]                  index_value;
  logic [31:0]                  store_register_value;
  logic                         negative;
  logic                         zero;
  logic                         carry;
  logic                         overflow;
  logic                         decode_match;
  logic                         encoding_valid;
  logic                         unpredictable_encoding;
  logic                         unpredictable_access;
  logic                         condition_passed;
  logic                         unconditional_space;
  logic                         execute_valid;
  arm9_misc_transfer_kind_e     transfer_kind;
  logic                         transfer_load;
  logic                         transfer_signed;
  logic                         transfer_halfword;
  logic [3:0]                   base_register;
  logic [3:0]                   data_register;
  logic [3:0]                   index_register;
  logic                         memory_request_valid;
  logic                         memory_write;
  logic                         memory_byte_transfer;
  logic                         memory_halfword_transfer;
  logic [31:0]                  memory_address;
  logic [31:0]                  memory_write_value;
  logic [15:0]                  memory_write_halfword_value;
  logic                         base_writeback_pending;
  logic [31:0]                  base_writeback_value;
  int unsigned                  cases_checked;

  arm9_misc_transfer_prepare dut (.*);

  function automatic logic reference_condition(
    input logic [3:0] condition,
    input logic n,
    input logic z,
    input logic c,
    input logic v
  );
    case (condition)
      4'h0: return z;
      4'h1: return !z;
      4'h2: return c;
      4'h3: return !c;
      4'h4: return n;
      4'h5: return !n;
      4'h6: return v;
      4'h7: return !v;
      4'h8: return c && !z;
      4'h9: return !c || z;
      4'ha: return n == v;
      4'hb: return n != v;
      4'hc: return !z && (n == v);
      4'hd: return z || (n != v);
      4'he: return 1'b1;
      default: return 1'b0;
    endcase
  endfunction

  function automatic logic [31:0] operation_encoding(
    input int unsigned operation_case
  );
    case (operation_case)
      0: return 32'he1c1_20b4;
      1: return 32'he1d1_20b4;
      2: return 32'he1d1_20d4;
      default: return 32'he1d1_20f4;
    endcase
  endfunction

  initial begin
    logic expected_condition;
    logic expected_encoding;
    logic expected_writeback;
    logic expected_load;
    logic expected_byte;
    logic [31:0] expected_adjusted;

    instruction = 32'he1d1_20b4;
    base_value = 32'h1000_0000;
    index_value = 32'h0000_0004;
    store_register_value = 32'h89ab_cdef;
    negative = 1'b0;
    zero = 1'b0;
    carry = 1'b0;
    overflow = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-ARM-MISC-TRANSFER-PREPARE-001
    // REQ: COMMON-ARM-MISC-TRANSFER-WRITEBACK-001
    for (int unsigned operation_case = 0; operation_case < 4;
         operation_case++) begin
      for (int unsigned immediate_case = 0; immediate_case < 2;
           immediate_case++) begin
        for (int unsigned controls = 0; controls < 8; controls++) begin
          for (int unsigned condition_case = 0; condition_case < 15;
               condition_case++) begin
            for (int unsigned flags = 0; flags < 16; flags++) begin
              instruction = operation_encoding(operation_case);
              instruction[31:28] = condition_case[3:0];
              instruction[24:23] = controls[2:1];
              instruction[22] = immediate_case[0];
              instruction[21] = controls[0];
              instruction[11:8] = 4'h0;
              instruction[3:0] = 4'h4;
              negative = flags[3];
              zero = flags[2];
              carry = flags[1];
              overflow = flags[0];
              expected_condition = reference_condition(
                condition_case[3:0], negative, zero, carry, overflow
              );
              expected_encoding = instruction[24] || !instruction[21];
              expected_writeback = !instruction[24] || instruction[21];
              expected_load = operation_case != 0;
              expected_byte = operation_case == 2;
              expected_adjusted = instruction[23] ?
                (base_value + 32'd4) : (base_value - 32'd4);
              #1ps;

              assert (decode_match);
              assert (encoding_valid == expected_encoding);
              assert (unpredictable_encoding == !expected_encoding);
              assert (!unpredictable_access);
              assert (condition_passed == expected_condition);
              assert (execute_valid ==
                      (expected_encoding && expected_condition));
              assert (memory_request_valid == execute_valid);
              assert (memory_write ==
                      (execute_valid && !expected_load));
              assert (memory_byte_transfer ==
                      (execute_valid && expected_byte));
              assert (memory_halfword_transfer ==
                      (execute_valid && !expected_byte));
              assert (memory_address ==
                      (instruction[24] ? expected_adjusted : base_value));
              assert (base_writeback_pending ==
                      (execute_valid && expected_writeback));
              assert (base_writeback_value == expected_adjusted);
              assert (transfer_load == expected_load);
              assert (transfer_signed == (operation_case >= 2));
              assert (transfer_halfword == !expected_byte);
              case (operation_case)
                0: assert (transfer_kind == ARM9_MISC_TRANSFER_STRH);
                1: assert (transfer_kind == ARM9_MISC_TRANSFER_LDRH);
                2: assert (transfer_kind == ARM9_MISC_TRANSFER_LDRSB);
                default: assert (transfer_kind == ARM9_MISC_TRANSFER_LDRSH);
              endcase
              assert (base_register == 4'h1);
              assert (data_register == 4'h2);
              assert (index_register == 4'h4);
              assert (memory_write_value == store_register_value);
              assert (memory_write_halfword_value ==
                      store_register_value[15:0]);
              assert (!unconditional_space);
              cases_checked++;
            end
          end
        end
      end
    end

    // REQ: COMMON-ARM-MISC-TRANSFER-ALIGNMENT-GATE-001
    for (int unsigned operation_case = 0; operation_case < 4;
         operation_case++) begin
      for (int unsigned pass_case = 0; pass_case < 2; pass_case++) begin
        instruction = operation_encoding(operation_case);
        instruction[31:28] = 4'h0;
        base_value = 32'h2000_0001;
        zero = pass_case[0];
        #1ps;
        assert (condition_passed == pass_case[0]);
        if ((operation_case != 2) && pass_case[0]) begin
          assert (unpredictable_access);
          assert (!execute_valid && !memory_request_valid);
        end else begin
          assert (!unpredictable_access);
          assert (execute_valid == pass_case[0]);
        end
        cases_checked++;
      end
    end

    assert (cases_checked == 15_368);
    $display("PASS conditioned ARM miscellaneous-transfer preparation (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
