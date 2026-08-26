# Cycle Timing

Cycle timing is specified independently for the ARM9TDMI Rev 3 and ARM946E-S
r1p1 profiles. The machine-readable instruction rows and their current verification
status are in `spec/timing/arm9tdmi_instruction_cycles.json` and
`spec/timing/arm9es_instruction_cycles.json`.

No integrated processor pipeline exists yet, so the project does not claim whole-core
cycle accuracy. The current synthesizable timing controllers cover data operations,
single and block transfers, branch and synchronous-exception refills, and PSR transfers.
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

## Remaining work

Swaps, multiply execution sequences, coprocessor operations, wait-state insertion,
the ARM9TDMI Harvard interfaces, ARM946E-S cache/TCM/write
buffer behavior, AHB transactions, debug, reset, interrupt recognition, and a real
five-stage pipeline are not yet cycle-verified. See `docs/ACCURACY.md` for the full
status matrix.
