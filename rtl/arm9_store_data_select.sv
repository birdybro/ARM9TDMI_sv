module arm9_store_data_select #(
  parameter arm9_profile_pkg::arm9_profile_e PROFILE =
    arm9_profile_pkg::ARM9_PROFILE_ARM9TDMI
) (
  input  logic [31:0] instruction_address,
  input  logic [3:0]  data_register,
  input  logic        byte_transfer,
  input  logic [31:0] register_value,
  input  logic [31:0] unresolved_profile_pc_value,
  output logic [31:0] store_value,
  output logic [7:0]  store_byte_value,
  output logic        pc_store_special_case,
  output logic        pc_store_value_documented,
  output logic        pc_store_value_unresolved
);
  import arm9_profile_pkg::*;

  always_comb begin
    pc_store_special_case = (data_register == 4'hf) && !byte_transfer;
    pc_store_value_documented = 1'b0;
    pc_store_value_unresolved = 1'b0;
    store_value = register_value;

    if (pc_store_special_case) begin
      if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
        store_value = instruction_address + 32'd12;
        pc_store_value_documented = 1'b1;
      end else begin
        // The reviewed public ARM9E-S and ARM946E-S TRMs do not select the
        // architecturally permitted +8/+12 value. Keep that uncertainty at
        // the profile boundary instead of silently inheriting ARM9TDMI +12.
        store_value = unresolved_profile_pc_value;
        pc_store_value_unresolved = 1'b1;
      end
    end

    store_byte_value = store_value[7:0];
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(pc_store_value_documented && pc_store_value_unresolved));
    assert (!(pc_store_value_documented && !pc_store_special_case));
    assert (!(pc_store_value_unresolved && !pc_store_special_case));

    if (!pc_store_special_case) begin
      assert (store_value == register_value);
    end else if (PROFILE == ARM9_PROFILE_ARM9TDMI) begin
      assert (store_value == instruction_address + 32'd12);
      assert (pc_store_value_documented && !pc_store_value_unresolved);
    end else begin
      assert (store_value == unresolved_profile_pc_value);
      assert (!pc_store_value_documented && pc_store_value_unresolved);
    end

    assert (store_byte_value == store_value[7:0]);
  end
`endif
endmodule
