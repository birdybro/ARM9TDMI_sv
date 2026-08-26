module profile_arm9tdmi_tb;
  import arm9_profile_pkg::*;

  arm9_profile_config_t profile_cfg;

  initial begin
    profile_cfg = profile_config(ARM9_PROFILE_ARM9TDMI);

    // REQ: ARM9TDMI-PROFILE-001
    assert (profile_cfg.architecture == ARM9_ARCH_V4T);
    assert (profile_cfg.integer_pipeline_stages == 5);

    // REQ: ARM9TDMI-PROFILE-002
    assert (!profile_cfg.has_v5te);
    assert (!profile_cfg.has_cp15);
    assert (!profile_cfg.has_mpu);
    assert (!profile_cfg.has_caches);
    assert (!profile_cfg.has_tcm);
    assert (!profile_cfg.has_write_buffer);
    assert (!profile_cfg.has_ahb);
    assert (!profile_cfg.has_etm_interface);

    // REQ: ARM9TDMI-MULTIPLIER-001
    assert (profile_cfg.multiply_early_termination);

    $display("PASS profile ARM9TDMI Rev 3 / ARMv4T");
    $finish;
  end
endmodule
