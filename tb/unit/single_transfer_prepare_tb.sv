module single_transfer_prepare_tb;
  logic [31:0] instruction;
  logic [31:0] base_value;
  logic [31:0] index_value;
  logic [31:0] store_register_value;
  logic negative;
  logic zero;
  logic carry;
  logic overflow;
  logic decode_match;
  logic encoding_valid;
  logic unpredictable_encoding;
  logic unpredictable_access;
  logic condition_passed;
  logic unconditional_space;
  logic execute_valid;
  logic transfer_load;
  logic transfer_byte;
  logic translated_access;
  logic [3:0] base_register;
  logic [3:0] data_register;
  logic [3:0] index_register;
  logic memory_request_valid;
  logic memory_write;
  logic memory_byte_transfer;
  logic memory_unprivileged;
  logic [31:0] memory_address;
  logic [31:0] memory_write_value;
  logic [7:0] memory_write_byte_value;
  logic base_writeback_pending;
  logic [31:0] base_writeback_value;
  logic store_pc_value_implementation_defined;
  int unsigned cases_checked;

  arm9_single_transfer_prepare dut (.*);

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

  initial begin
    logic expected_condition;
    logic expected_writeback;
    logic [31:0] expected_adjusted;

    instruction          = 32'he591_2004;
    base_value           = 32'h1000_0000;
    index_value          = 32'h0000_0004;
    store_register_value = 32'h89ab_cdef;
    negative             = 1'b0;
    zero                 = 1'b0;
    carry                = 1'b0;
    overflow             = 1'b0;
    cases_checked        = 0;

    // REQ: COMMON-ARM-SINGLE-TRANSFER-PREPARE-001
    // REQ: COMMON-ARM-SINGLE-TRANSFER-WRITEBACK-001
    for (int unsigned register_form = 0; register_form < 2;
         register_form++) begin
      for (int unsigned controls = 0; controls < 32; controls++) begin
        for (int unsigned condition = 0; condition < 15; condition++) begin
          for (int unsigned flags = 0; flags < 16; flags++) begin
            instruction = register_form[0] ? 32'he601_2003 :
                                             32'he401_2004;
            instruction[31:28] = condition[3:0];
            instruction[24:20] = controls[4:0];
            negative = flags[3];
            zero     = flags[2];
            carry    = flags[1];
            overflow = flags[0];
            expected_condition = reference_condition(
              condition[3:0], negative, zero, carry, overflow
            );
            expected_writeback = !instruction[24] || instruction[21];
            expected_adjusted = instruction[23] ?
              (base_value + 32'd4) : (base_value - 32'd4);
            #1ps;

            assert (decode_match && encoding_valid);
            assert (!unpredictable_encoding);
            assert (!unpredictable_access);
            assert (condition_passed == expected_condition);
            assert (execute_valid == expected_condition);
            assert (memory_request_valid == expected_condition);
            assert (memory_write ==
                    (expected_condition && !instruction[20]));
            assert (memory_byte_transfer ==
                    (expected_condition && instruction[22]));
            assert (memory_unprivileged ==
                    (expected_condition && !instruction[24] &&
                     instruction[21]));
            assert (memory_address ==
                    (instruction[24] ? expected_adjusted : base_value));
            assert (base_writeback_pending ==
                    (expected_condition && expected_writeback));
            assert (base_writeback_value == expected_adjusted);
            assert (transfer_load == instruction[20]);
            assert (transfer_byte == instruction[22]);
            assert (translated_access ==
                    (!instruction[24] && instruction[21]));
            assert (base_register == 4'h1);
            assert (data_register == 4'h2);
            assert (index_register ==
                    (register_form[0] ? 4'h3 : 4'h4));
            assert (memory_write_value == store_register_value);
            assert (memory_write_byte_value == store_register_value[7:0]);
            assert (!store_pc_value_implementation_defined);
            assert (!unconditional_space);
            cases_checked++;
          end
        end
      end
    end

    // REQ: COMMON-ARM-STR-PC-UNCERTAINTY-SIGNAL-001
    instruction = 32'he581_f004;
    store_register_value = 32'hfeed_c0de;
    #1ps;
    assert (encoding_valid && memory_request_valid && memory_write);
    assert (store_pc_value_implementation_defined);
    assert (memory_write_value == 32'hfeed_c0de);
    cases_checked++;

    instruction[31:28] = 4'h0;
    zero = 1'b0;
    #1ps;
    assert (encoding_valid && !memory_request_valid && !memory_write);
    assert (store_pc_value_implementation_defined);
    cases_checked++;

    instruction = 32'he591_f004;
    #1ps;
    assert (encoding_valid && memory_request_valid && transfer_load);
    assert (!unpredictable_access);
    assert (!store_pc_value_implementation_defined);
    cases_checked++;

    instruction = 32'he591_f001;
    #1ps;
    assert (encoding_valid && !unpredictable_encoding);
    assert (unpredictable_access && !execute_valid);
    assert (!memory_request_valid && !base_writeback_pending);
    cases_checked++;

    instruction = 32'he5d1_f004;
    #1ps;
    assert (unpredictable_encoding && !encoding_valid);
    assert (!memory_request_valid && !base_writeback_pending);
    assert (!store_pc_value_implementation_defined);
    cases_checked++;

    instruction = 32'hf591_2004;
    #1ps;
    assert (!decode_match && !encoding_valid && !execute_valid);
    assert (unconditional_space && !memory_request_valid);
    assert (!base_writeback_pending);
    cases_checked++;

    assert (cases_checked == 15_366);
    $display("PASS condition-gated ARM single-transfer preparation (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
