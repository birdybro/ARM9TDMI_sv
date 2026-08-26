module exception_arbiter_tb;
  import arm9_arch_pkg::*;

  logic reset_request;
  logic data_abort_request;
  logic fiq_request;
  logic irq_request;
  logic prefetch_abort_request;
  logic undefined_request;
  logic swi_request;
  logic cpsr_fiq_mask;
  logic cpsr_irq_mask;
  logic selected_valid;
  arm9_exception_kind_e selected_kind;
  logic masked_fiq_pending;
  logic masked_irq_pending;
  logic instruction_request_conflict;
  int unsigned cases_checked;

  arm9_exception_arbiter dut (.*);

  task automatic expected_selection(
    output logic expected_valid,
    output arm9_exception_kind_e expected_kind
  );
    expected_valid = 1'b1;
    expected_kind = ARM9_EXCEPTION_RESET;
    if (reset_request) begin
      expected_kind = ARM9_EXCEPTION_RESET;
    end else if (data_abort_request) begin
      expected_kind = ARM9_EXCEPTION_DATA_ABORT;
    end else if (fiq_request && !cpsr_fiq_mask) begin
      expected_kind = ARM9_EXCEPTION_FIQ;
    end else if (irq_request && !cpsr_irq_mask) begin
      expected_kind = ARM9_EXCEPTION_IRQ;
    end else if (prefetch_abort_request) begin
      expected_kind = ARM9_EXCEPTION_PREFETCH_ABORT;
    end else if (undefined_request) begin
      expected_kind = ARM9_EXCEPTION_UNDEFINED;
    end else if (swi_request) begin
      expected_kind = ARM9_EXCEPTION_SWI;
    end else begin
      expected_valid = 1'b0;
      expected_kind = ARM9_EXCEPTION_RESET;
    end
  endtask

  initial begin
    logic expected_valid;
    arm9_exception_kind_e expected_kind;

    reset_request = 1'b0;
    data_abort_request = 1'b0;
    fiq_request = 1'b0;
    irq_request = 1'b0;
    prefetch_abort_request = 1'b0;
    undefined_request = 1'b0;
    swi_request = 1'b0;
    cpsr_fiq_mask = 1'b0;
    cpsr_irq_mask = 1'b0;
    cases_checked = 0;

    // REQ: COMMON-EXCEPTION-PRIORITY-001
    // REQ: COMMON-INTERRUPT-MASKING-001
    for (int unsigned requests = 0; requests < 128; requests++) begin
      if (requests[1:0] == 2'b11) begin
        continue;
      end
      for (int unsigned masks = 0; masks < 4; masks++) begin
        {reset_request, data_abort_request, fiq_request, irq_request,
         prefetch_abort_request, undefined_request, swi_request} =
          requests[6:0];
        {cpsr_fiq_mask, cpsr_irq_mask} = masks[1:0];
        expected_selection(expected_valid, expected_kind);
        #1ps;

        assert (!instruction_request_conflict);
        assert (selected_valid == expected_valid);
        assert (selected_kind == expected_kind);
        assert (masked_fiq_pending ==
                (fiq_request && cpsr_fiq_mask));
        assert (masked_irq_pending ==
                (irq_request && cpsr_irq_mask));
        cases_checked++;
      end
    end

    undefined_request = 1'b1;
    swi_request = 1'b1;
    reset_request = 1'b0;
    data_abort_request = 1'b0;
    fiq_request = 1'b0;
    irq_request = 1'b0;
    prefetch_abort_request = 1'b0;
    cpsr_fiq_mask = 1'b0;
    cpsr_irq_mask = 1'b0;
    #1ps;
    assert (instruction_request_conflict && !selected_valid);

    assert (cases_checked == 384);
    $display("PASS exhaustive exception priority and masking (%0d cases)",
             cases_checked);
    $finish;
  end
endmodule
