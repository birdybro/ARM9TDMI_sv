package arm9_isa_pkg;
  typedef enum logic [1:0] {
    ARM9_SHIFT_LSL = 2'b00,
    ARM9_SHIFT_LSR = 2'b01,
    ARM9_SHIFT_ASR = 2'b10,
    ARM9_SHIFT_ROR = 2'b11
  } arm9_shift_type_e;

  typedef enum logic [3:0] {
    ARM9_DATA_AND = 4'b0000,
    ARM9_DATA_EOR = 4'b0001,
    ARM9_DATA_SUB = 4'b0010,
    ARM9_DATA_RSB = 4'b0011,
    ARM9_DATA_ADD = 4'b0100,
    ARM9_DATA_ADC = 4'b0101,
    ARM9_DATA_SBC = 4'b0110,
    ARM9_DATA_RSC = 4'b0111,
    ARM9_DATA_TST = 4'b1000,
    ARM9_DATA_TEQ = 4'b1001,
    ARM9_DATA_CMP = 4'b1010,
    ARM9_DATA_CMN = 4'b1011,
    ARM9_DATA_ORR = 4'b1100,
    ARM9_DATA_MOV = 4'b1101,
    ARM9_DATA_BIC = 4'b1110,
    ARM9_DATA_MVN = 4'b1111
  } arm9_data_opcode_e;

  typedef enum logic [2:0] {
    ARM9_BRANCH_B,
    ARM9_BRANCH_BL,
    ARM9_BRANCH_BX,
    ARM9_BRANCH_BLX_IMMEDIATE,
    ARM9_BRANCH_BLX_REGISTER
  } arm9_branch_kind_e;

  typedef enum logic [2:0] {
    ARM9_MULTIPLY_MUL,
    ARM9_MULTIPLY_MLA,
    ARM9_MULTIPLY_UMULL,
    ARM9_MULTIPLY_UMLAL,
    ARM9_MULTIPLY_SMULL,
    ARM9_MULTIPLY_SMLAL,
    ARM9_MULTIPLY_DSP_SHORT,
    ARM9_MULTIPLY_DSP_LONG
  } arm9_multiply_kind_e;

  typedef enum logic [2:0] {
    ARM9_DSP_MULTIPLY_SMLA_XY,
    ARM9_DSP_MULTIPLY_SMLAW_Y,
    ARM9_DSP_MULTIPLY_SMULW_Y,
    ARM9_DSP_MULTIPLY_SMLAL_XY,
    ARM9_DSP_MULTIPLY_SMUL_XY
  } arm9_dsp_multiply_kind_e;

  typedef enum logic [1:0] {
    ARM9_SATURATING_QADD  = 2'b00,
    ARM9_SATURATING_QSUB  = 2'b01,
    ARM9_SATURATING_QDADD = 2'b10,
    ARM9_SATURATING_QDSUB = 2'b11
  } arm9_saturating_kind_e;

  typedef enum logic [1:0] {
    ARM9_MISC_TRANSFER_STRH,
    ARM9_MISC_TRANSFER_LDRH,
    ARM9_MISC_TRANSFER_LDRSB,
    ARM9_MISC_TRANSFER_LDRSH
  } arm9_misc_transfer_kind_e;
endpackage
