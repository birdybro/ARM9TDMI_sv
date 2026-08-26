module arm9_exception_arbiter (
  input  logic                                reset_request,
  input  logic                                data_abort_request,
  input  logic                                fiq_request,
  input  logic                                irq_request,
  input  logic                                prefetch_abort_request,
  input  logic                                undefined_request,
  input  logic                                swi_request,
  input  logic                                cpsr_fiq_mask,
  input  logic                                cpsr_irq_mask,
  output logic                                selected_valid,
  output arm9_arch_pkg::arm9_exception_kind_e selected_kind,
  output logic                                masked_fiq_pending,
  output logic                                masked_irq_pending,
  output logic                                instruction_request_conflict
);
  import arm9_arch_pkg::*;

  always_comb begin
    masked_fiq_pending = fiq_request && cpsr_fiq_mask;
    masked_irq_pending = irq_request && cpsr_irq_mask;
    instruction_request_conflict = undefined_request && swi_request;

    selected_valid = 1'b1;
    selected_kind = ARM9_EXCEPTION_RESET;
    if (reset_request) begin
      selected_kind = ARM9_EXCEPTION_RESET;
    end else if (data_abort_request) begin
      selected_kind = ARM9_EXCEPTION_DATA_ABORT;
    end else if (fiq_request && !cpsr_fiq_mask) begin
      selected_kind = ARM9_EXCEPTION_FIQ;
    end else if (irq_request && !cpsr_irq_mask) begin
      selected_kind = ARM9_EXCEPTION_IRQ;
    end else if (prefetch_abort_request) begin
      selected_kind = ARM9_EXCEPTION_PREFETCH_ABORT;
    end else if (instruction_request_conflict) begin
      selected_valid = 1'b0;
      selected_kind = ARM9_EXCEPTION_UNDEFINED;
    end else if (undefined_request) begin
      selected_kind = ARM9_EXCEPTION_UNDEFINED;
    end else if (swi_request) begin
      selected_kind = ARM9_EXCEPTION_SWI;
    end else begin
      selected_valid = 1'b0;
      selected_kind = ARM9_EXCEPTION_RESET;
    end
  end

`ifndef SYNTHESIS
  always_comb begin
    assert (!(masked_fiq_pending && !fiq_request));
    assert (!(masked_irq_pending && !irq_request));
    assert (!(selected_valid && instruction_request_conflict &&
              !reset_request && !data_abort_request &&
              !(fiq_request && !cpsr_fiq_mask) &&
              !(irq_request && !cpsr_irq_mask) &&
              !prefetch_abort_request));
    if (selected_valid && (selected_kind == ARM9_EXCEPTION_FIQ)) begin
      assert (fiq_request && !cpsr_fiq_mask);
    end
    if (selected_valid && (selected_kind == ARM9_EXCEPTION_IRQ)) begin
      assert (irq_request && !cpsr_irq_mask);
    end
  end
`endif
endmodule
