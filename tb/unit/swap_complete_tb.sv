module swap_complete_tb;
  logic        read_access_complete;
  logic        read_data_abort;
  logic        write_access_complete;
  logic        write_data_abort;
  logic        byte_swap;
  logic [1:0]  original_address_low;
  logic [31:0] aligned_read_word;
  logic [7:0]  selected_read_byte;
  logic [3:0]  destination_register;
  logic        store_access_permitted;
  logic        store_access_canceled_on_read_abort;
  logic        sequence_complete;
  logic        data_abort_taken;
  logic        loaded_word_rotation_applied;
  logic        destination_write_valid;
  logic [3:0]  destination_write_register;
  logic [31:0] destination_write_value;
  int unsigned cases_checked;

  arm9_swap_complete dut (.*);

  function automatic logic [31:0] rotate_word(
    input logic [31:0] value,
    input logic [1:0] address_low
  );
    case (address_low)
      2'b00: return value;
      2'b01: return {value[7:0], value[31:8]};
      2'b10: return {value[15:0], value[31:16]};
      2'b11: return {value[23:0], value[31:24]};
      default: return 'x;
    endcase
  endfunction

  task automatic check_case(
    input logic       read_complete,
    input logic       read_abort,
    input logic       write_complete,
    input logic       write_abort,
    input logic       is_byte,
    input logic [1:0] address_low,
    input logic [3:0] register_number,
    input logic [1:0] data_case
  );
    logic expected_store_permitted;
    logic expected_read_abort_cancel;
    logic expected_sequence_complete;
    logic expected_abort;
    logic [31:0] expected_value;

    read_access_complete = read_complete;
    read_data_abort = read_abort;
    write_access_complete = write_complete;
    write_data_abort = write_abort;
    byte_swap = is_byte;
    original_address_low = address_low;
    destination_register = register_number;
    case (data_case)
      2'd0: begin
        aligned_read_word = 32'h0123_4567;
        selected_read_byte = 8'h80;
      end
      2'd1: begin
        aligned_read_word = 32'h89ab_cdef;
        selected_read_byte = 8'hff;
      end
      2'd2: begin
        aligned_read_word = 32'ha55a_00ff;
        selected_read_byte = 8'h01;
      end
      default: begin
        aligned_read_word = 32'hffff_ffff;
        selected_read_byte = 8'h7e;
      end
    endcase
    #1ps;

    expected_store_permitted = read_complete && !read_abort;
    expected_read_abort_cancel = read_complete && read_abort;
    expected_sequence_complete = expected_read_abort_cancel ||
                                 write_complete;
    expected_abort = expected_read_abort_cancel ||
                     (write_complete && write_abort);
    expected_value = is_byte ? {24'b0, selected_read_byte} :
                               rotate_word(aligned_read_word, address_low);

    assert (store_access_permitted == expected_store_permitted);
    assert (store_access_canceled_on_read_abort ==
            expected_read_abort_cancel);
    assert (sequence_complete == expected_sequence_complete);
    assert (data_abort_taken == expected_abort);
    assert (loaded_word_rotation_applied ==
            (!is_byte && (address_low != 2'b00)));
    assert (destination_write_valid ==
            (write_complete && !write_abort));
    assert (destination_write_register == register_number);
    assert (destination_write_value == expected_value);
    cases_checked++;
  endtask

  initial begin
    read_access_complete = 1'b0;
    read_data_abort = 1'b0;
    write_access_complete = 1'b0;
    write_data_abort = 1'b0;
    byte_swap = 1'b0;
    original_address_low = 2'b0;
    aligned_read_word = '0;
    selected_read_byte = '0;
    destination_register = 4'h0;
    cases_checked = 0;

    // REQ: COMMON-ARM-SWP-COMPLETE-001
    // REQ: COMMON-ARM-SWP-PRECISE-ABORT-001
    for (int unsigned byte_case = 0; byte_case < 2; byte_case++) begin
      for (int unsigned address_case = 0; address_case < 4;
           address_case++) begin
        for (int unsigned register_case = 0; register_case < 15;
             register_case++) begin
          for (int unsigned data_case = 0; data_case < 4; data_case++) begin
            check_case(1'b0, 1'b0, 1'b0, 1'b0, byte_case[0],
                       address_case[1:0], register_case[3:0], data_case[1:0]);
            check_case(1'b1, 1'b0, 1'b0, 1'b0, byte_case[0],
                       address_case[1:0], register_case[3:0], data_case[1:0]);
            check_case(1'b1, 1'b1, 1'b0, 1'b0, byte_case[0],
                       address_case[1:0], register_case[3:0], data_case[1:0]);
            check_case(1'b1, 1'b0, 1'b1, 1'b0, byte_case[0],
                       address_case[1:0], register_case[3:0], data_case[1:0]);
            check_case(1'b1, 1'b0, 1'b1, 1'b1, byte_case[0],
                       address_case[1:0], register_case[3:0], data_case[1:0]);
          end
        end
      end
    end

    assert (cases_checked == 2400);
    $display("PASS common ARM swap completion (%0d cases)", cases_checked);
    $finish;
  end
endmodule
