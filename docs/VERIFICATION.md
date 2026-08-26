# Verification

## Current executable gates

The project currently verifies its source/specification database and explicit profile
configuration. No ISA or cycle-accurate processor RTL exists yet, so passing these
gates is not evidence that a processor is complete.

```sh
make toolchain
make spec
make lint
make compile
make test
make test-arm9tdmi
make test-arm946es
make test-timing
make regression
```

`make test-formal` and `make synth` fail with an explicit missing-tool diagnostic
until SymbiYosys and Yosys are installed. They will not silently report success.

## Initial validated tools

- Verilator 5.050: SystemVerilog lint, elaboration, assertions, executable tests
- Python 3.14.6: specification validation and unit-test orchestration
- GNU Make: reproducible entry points
- QEMU 11.1.0: available for future architectural differential tests only; never a
  timing oracle

Icarus Verilog, Yosys, SymbiYosys, SMT solvers, and the GNU Arm bare-metal
toolchain were not installed at the initial audit. CI installs the tools used by its
jobs; local discovery is reported by `make toolchain`.

## Traceability

Tests cite requirement IDs using `REQ:` annotations. `tools/validate_spec.py` checks
that cited IDs exist, that source locators resolve to registered documents, and that
`VERIFIED` requirements name concrete RTL and tests.

Randomized tests must print the seed, profile, simulator, initial state, memory-system
configuration, and a replay command. This contract will be encoded with the first
random test generator.
