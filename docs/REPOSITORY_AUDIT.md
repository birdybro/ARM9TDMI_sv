# Repository Audit

Audit date: 2026-08-25

## Initial state

- Branch: `main`
- Upstream: `origin/main`
- Remote: `https://github.com/birdybro/ARM9TDMI_sv.git`
- Initial HEAD: `52f46329463d0f53d4e5130a45222521d7f9da08`
- Initial worktree: clean
- Tracked files: `README.md`, `LICENSE`
- Other local or remote branches: none
- Existing RTL, tests, scripts, CI, and build system: none
- Existing TODO/FIXME/HACK/STUB markers: none
- Repository-specific `AGENTS.md`: none

No pre-existing user changes or architectural decisions required preservation. The
project begins from a two-file repository skeleton.

## Initial validation baseline

There was no test, lint, elaboration, formal, or synthesis target to run. Therefore
the baseline is **not applicable**, not passing. The first executable milestone must
establish reproducible gates before functional RTL is introduced.

## Available host tools

| Tool | Initial availability |
|---|---|
| Verilator | 5.050 |
| Python | 3.14.6 |
| pytest | installed |
| QEMU system ARM | 11.1.0 |
| Make, CMake, Ninja | installed |
| GCC, Clang | installed |
| Icarus Verilog | not installed |
| Yosys | not installed |
| SymbiYosys | not installed |
| Boolector/Z3 | not installed |
| GNU Arm bare-metal toolchain | not installed |

Missing optional tools will be detected explicitly by the build system. Verilator is
the initial simulator/linter. A second simulator and synthesis/formal tools must be
added or documented before the corresponding acceptance gates can be claimed.

## Initial Git history

The only initial commit is `52f4632 Initial commit`. No historical RTL or discarded
implementation exists on any visible branch.
