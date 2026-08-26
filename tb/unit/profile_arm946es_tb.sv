module profile_arm946es_tb;
  import arm9_profile_pkg::*;

  arm9_profile_config_t profile_cfg;

  initial begin
    profile_cfg = profile_config(ARM9_PROFILE_ARM946ES);

    // REQ: ARM946ES-PROFILE-001
    assert (profile_cfg.architecture == ARM9_ARCH_V5TE);
    assert (profile_cfg.has_v5te);
    assert (ARM9_INTEGER_PIPELINE_STAGES == 5);

    // REQ: ARM946ES-PROFILE-002
    assert (profile_cfg.has_cp15);
    assert (profile_cfg.has_mpu);
    assert (profile_cfg.has_caches);
    assert (profile_cfg.has_tcm);
    assert (profile_cfg.has_write_buffer);
    assert (profile_cfg.has_ahb);
    assert (profile_cfg.has_etm_interface);

    // REQ: ARM946ES-MULTIPLIER-001
    assert (!profile_cfg.multiply_early_termination);

    $display("PASS profile ARM946E-S r1p1 / ARMv5TE");
    $finish;
  end
endmodule
