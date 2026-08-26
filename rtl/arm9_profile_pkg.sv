package arm9_profile_pkg;
  typedef enum logic {
    ARM9_PROFILE_ARM9TDMI = 1'b0,
    ARM9_PROFILE_ARM946ES = 1'b1
  } arm9_profile_e;

  typedef enum logic [3:0] {
    ARM9_ARCH_V4T  = 4'd4,
    ARM9_ARCH_V5TE = 4'd5
  } arm9_architecture_e;

  typedef struct packed {
    arm9_architecture_e architecture;
    logic               has_v5te;
    logic               has_cp15;
    logic               has_mpu;
    logic               has_caches;
    logic               has_tcm;
    logic               has_write_buffer;
    logic               has_ahb;
    logic               has_etm_interface;
    logic               multiply_early_termination;
  } arm9_profile_config_t;

  localparam int unsigned ARM9_INTEGER_PIPELINE_STAGES = 5;

  function automatic arm9_profile_config_t profile_config(
    input arm9_profile_e profile
  );
    arm9_profile_config_t profile_cfg;

    profile_cfg = '0;
    case (profile)
      ARM9_PROFILE_ARM9TDMI: begin
        profile_cfg.architecture               = ARM9_ARCH_V4T;
        profile_cfg.multiply_early_termination = 1'b1;
      end
      ARM9_PROFILE_ARM946ES: begin
        profile_cfg.architecture      = ARM9_ARCH_V5TE;
        profile_cfg.has_v5te          = 1'b1;
        profile_cfg.has_cp15          = 1'b1;
        profile_cfg.has_mpu           = 1'b1;
        profile_cfg.has_caches        = 1'b1;
        profile_cfg.has_tcm           = 1'b1;
        profile_cfg.has_write_buffer  = 1'b1;
        profile_cfg.has_ahb           = 1'b1;
        profile_cfg.has_etm_interface = 1'b1;
      end
      default: profile_cfg = 'x;
    endcase

    return profile_cfg;
  endfunction
endpackage
