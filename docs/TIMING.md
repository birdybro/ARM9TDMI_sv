# Cycle Timing

Cycle timing is specified independently for the ARM9TDMI Rev 3 and ARM946E-S
r1p1 profiles. The machine-readable instruction rows and their current verification
status are in `spec/timing/arm9tdmi_instruction_cycles.json` and
`spec/timing/arm9es_instruction_cycles.json`.

No integrated processor pipeline exists yet, so the project does not claim whole-core
cycle accuracy. The current synthesizable timing controllers cover data operations,
single, block, and ARM946E-S doubleword transfers, swaps, branch and
synchronous-exception refills, PSR transfers, and ARM946E-S PLD hints.
Each controller exposes the active cycle, total latency, aggregate instruction/data
bus classes, and a completion pulse. Tests check every active cycle and the completion
edge for both profiles.

## Evidence policy

When a processor TRM publishes only aggregate bus classes, the RTL reports exact
latency and aggregate counts but leaves chronological cycle type explicitly
`UNSPECIFIED`. It does not import ARM9E-S ordering into ARM9TDMI. Where DDI0165B
provides signal-by-signal tables, the ARM946E-S profile implements and tests their
exact cycle order.

The currently verified ARM9E-S orders include:

- data operations: normal `S`; register shift `I,S`; PC result `N,S,S`; both
  qualifications `I,N,S,S`
- LDR/STR: normal `S/N`; word load-use `I,S / N,I`; byte, halfword, or unaligned
  load-use `I,I,S / N,I,I`; PC load `I,I,N,S,S / N,I,I,I,I`
- LDM/STM: exact Table 8-23 and Table 8-24 orders for every legal transfer count,
  including final-word interlock and PC refill cases
- LDRD/STRD: the documented two-register LDM/STM mapping, including the LDRD
  final-word interlock, with ARM9TDMI profile rejection
- PLD: one `S / I` cycle with the calculated data address broadcast and the
  logical data-speculative indication asserted; ARM9TDMI rejects the operation
- SWP/SWPB: normal `I,S / N,N`; one-cycle interlock `I,I,S / N,N,I`;
  two-cycle interlock `I,I,I,S / N,N,I,I`, with the atomic read, write, and
  DLOCK window identified independently of the aggregate bus classes
- B/BL/BX/BLX and exception entry: `N,S,S / I,I,I`
- MRS: `I,S`; non-flags-only MSR: `I,I,S`

Here `I`, `N`, and `S` mean internal, nonsequential, and sequential bus cycles. A
slash separates instruction-bus and data-bus order.

## DDI0165B one-register LDM conflict

DDI0165B contains an internal conflict for a one-register LDM that does not load PC:

- §8.1 Table 8-2 summarizes the data bus as `1S+1I`.
- §8.14 Table 8-23 explicitly shows cycle 1 as `N` and cycle 2 as `I`.
- ARM946E-S r1p1 errata issue 5.0 does not correct either table.

For ARM946E-S, this project uses `1N+1I` because Table 8-23 is the more specific,
signal-by-signal timing source. ARM9TDMI remains `1S+1I` because DDI0180A Table 7-2
is directly applicable and no detailed ARM9TDMI table resolving it was found. This
decision is encoded in the specification database and guarded by
`tests/timing/test_timing_spec.py`.

## DDI0180A SWP data-bus conflict

DDI0180A also conflicts internally on the normal SWP data-bus classification:

- §7.1 Table 7-2 gives `2N` alongside the instruction's two processor cycles.
- §7.1 Table 7-3 gives `1N+1S` from the data-bus perspective.
- The same pair of entries appears in ARM9TDMI Rev 0 and Rev 2 manuals.

The ARM9TDMI profile uses `2N`. This matches the cycle-aligned Table 7-2, the
same-address read-to-write transition, and the later ARM9E-S signal-level Table 8-25.
Because DDI0180A does not show the complete per-cycle SWP signal schedule, its
chronological bus-class outputs remain `UNSPECIFIED`; the atomic read then write order
and DLOCK window are represented separately. The decision and cross-revision check
are machine-readable and covered by the timing-specification tests.

## Remaining work

Multiply execution sequences, coprocessor operations, wait-state insertion, the
ARM9TDMI Harvard interfaces, ARM946E-S cache/TCM/write
buffer behavior, AHB transactions, debug, reset, interrupt recognition, and a real
five-stage pipeline are not yet cycle-verified. See `docs/ACCURACY.md` for the full
status matrix.
