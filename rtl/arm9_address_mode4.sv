module arm9_address_mode4 (
  input  logic [31:0] instruction,
  input  logic [31:0] base_value,
  output logic        decode_match,
  output logic        encoding_valid,
  output logic        unpredictable_encoding,
  output logic [3:0]  condition,
  output logic        pre_index,
  output logic        increment,
  output logic        psr_or_user,
  output logic        writeback,
  output logic        load,
  output logic [3:0]  base_register,
  output logic [15:0] register_list,
  output logic [4:0]  register_count,
  output logic [3:0]  first_register,
  output logic [3:0]  last_register,
  output logic        load_pc,
  output logic        user_bank_transfer,
  output logic        restore_cpsr,
  output logic        privileged_mode_required,
  output logic        spsr_required,
  output logic        base_in_register_list,
  output logic        load_base_writeback_unpredictable,
  output logic        store_base_uses_original_value,
  output logic        store_base_value_unpredictable,
  output logic        unaligned_base,
  output logic [31:0] start_address,
  output logic [31:0] end_address,
  output logic [31:0] writeback_address
);
  logic        first_found;
  logic        lower_register_selected;
  logic [31:0] aligned_base;
  logic [31:0] transfer_bytes;

  always_comb begin
    condition     = instruction[31:28];
    pre_index     = instruction[24];
    increment     = instruction[23];
    psr_or_user   = instruction[22];
    writeback     = instruction[21];
    load          = instruction[20];
    base_register = instruction[19:16];
    register_list = instruction[15:0];

    register_count = 5'b0;
    first_register = 4'b0;
    last_register = 4'b0;
    first_found = 1'b0;
    lower_register_selected = 1'b0;
    for (int unsigned index = 0; index < 16; index++) begin
      if (register_list[index]) begin
        register_count = register_count + 5'd1;
        if (!first_found) begin
          first_register = 4'(index);
          first_found = 1'b1;
        end
        last_register = 4'(index);
        if (index < int'(base_register)) begin
          lower_register_selected = 1'b1;
        end
      end
    end

    load_pc = load && register_list[15];
    restore_cpsr = psr_or_user && load_pc;
    user_bank_transfer = psr_or_user && !load_pc;
    privileged_mode_required = psr_or_user;
    spsr_required = restore_cpsr;
    base_in_register_list = register_list[base_register];

    decode_match = (condition != 4'b1111) &&
                   (instruction[27:25] == 3'b100);
    unpredictable_encoding = decode_match &&
      ((base_register == 4'hf) || (register_count == 5'd0) ||
       (user_bank_transfer && writeback));
    encoding_valid = decode_match && !unpredictable_encoding;

    load_base_writeback_unpredictable = encoding_valid && load &&
                                        writeback &&
                                        base_in_register_list;
    store_base_uses_original_value = encoding_valid && !load &&
                                     writeback &&
                                     base_in_register_list &&
                                     !lower_register_selected;
    store_base_value_unpredictable = encoding_valid && !load &&
                                     writeback &&
                                     base_in_register_list &&
                                     lower_register_selected;

    aligned_base = {base_value[31:2], 2'b00};
    unaligned_base = base_value[1:0] != 2'b00;
    transfer_bytes = {25'b0, register_count, 2'b00};
    if (increment) begin
      start_address = aligned_base + (pre_index ? 32'd4 : 32'd0);
      end_address = aligned_base + transfer_bytes -
                    (pre_index ? 32'd0 : 32'd4);
      writeback_address = base_value + transfer_bytes;
    end else begin
      start_address = aligned_base - transfer_bytes +
                      (pre_index ? 32'd0 : 32'd4);
      end_address = aligned_base - (pre_index ? 32'd4 : 32'd0);
      writeback_address = base_value - transfer_bytes;
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(encoding_valid && !decode_match));
    assert (!(encoding_valid && unpredictable_encoding));
    assert (!(restore_cpsr && user_bank_transfer));
    assert (privileged_mode_required == psr_or_user);
    assert (spsr_required == restore_cpsr);
    assert (!(load_base_writeback_unpredictable &&
              (!encoding_valid || !load || !writeback ||
               !base_in_register_list)));
    assert (!(store_base_uses_original_value &&
              store_base_value_unpredictable));
    assert (!(store_base_uses_original_value &&
              (!encoding_valid || load || !writeback ||
               !base_in_register_list)));
    assert (!(store_base_value_unpredictable &&
              (!encoding_valid || load || !writeback ||
               !base_in_register_list)));
    if (encoding_valid) begin
      assert (base_register != 4'hf);
      assert (register_count != 5'd0);
      assert (!(user_bank_transfer && writeback));
      assert (start_address[1:0] == 2'b00);
      assert (end_address[1:0] == 2'b00);
    end
  end
`endif
endmodule
