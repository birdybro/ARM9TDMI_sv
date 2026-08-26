module arm9_data_processing_decoder (
  input  logic [31:0]                      instruction,
  output logic                             decode_match,
  output logic                             encoding_valid,
  output logic                             unpredictable_encoding,
  output logic [3:0]                       condition,
  output logic                             immediate_operand,
  output arm9_isa_pkg::arm9_data_opcode_e opcode,
  output logic                             set_flags,
  output logic [3:0]                       first_register,
  output logic [3:0]                       destination_register,
  output logic [7:0]                       immediate_value,
  output logic [3:0]                       rotate_imm,
  output logic [3:0]                       shift_register,
  output logic [4:0]                       immediate_shift_amount,
  output arm9_isa_pkg::arm9_shift_type_e  shift_type,
  output logic                             shift_amount_from_register,
  output logic [3:0]                       shifted_register
);
  import arm9_isa_pkg::*;

  logic test_or_compare;
  logic unary_move;
  logic extension_space;
  logic sbz_violation;
  logic register_shift_pc_violation;

  always_comb begin
    condition                  = instruction[31:28];
    immediate_operand          = instruction[25];
    opcode                     = arm9_data_opcode_e'(instruction[24:21]);
    set_flags                  = instruction[20];
    first_register             = instruction[19:16];
    destination_register       = instruction[15:12];
    immediate_value            = instruction[7:0];
    rotate_imm                 = instruction[11:8];
    shift_register             = instruction[11:8];
    immediate_shift_amount     = instruction[11:7];
    shift_type                 = arm9_shift_type_e'(instruction[6:5]);
    shift_amount_from_register = !instruction[25] && instruction[4];
    shifted_register           = instruction[3:0];

    test_or_compare = instruction[24:23] == 2'b10;
    unary_move      = (instruction[24:21] == ARM9_DATA_MOV) ||
                      (instruction[24:21] == ARM9_DATA_MVN);
    extension_space = !instruction[25] && instruction[7] &&
                      instruction[4];

    decode_match = (condition != 4'b1111) &&
                   (instruction[27:26] == 2'b00) &&
                   !extension_space &&
                   !(test_or_compare && !instruction[20]);

    sbz_violation = (test_or_compare &&
                     (instruction[15:12] != 4'b0000)) ||
                    (unary_move &&
                     (instruction[19:16] != 4'b0000));
    register_shift_pc_violation = shift_amount_from_register &&
      ((first_register == 4'hf) ||
       (destination_register == 4'hf) ||
       (shift_register == 4'hf) ||
       (shifted_register == 4'hf));
    encoding_valid = decode_match && !sbz_violation &&
                     !register_shift_pc_violation;
    unpredictable_encoding = decode_match &&
      (sbz_violation || register_shift_pc_violation);
  end
endmodule
