# ARM9TDMI_sv

Cycle-accurate, synthesizable SystemVerilog reimplementation project for two explicit
processor profiles:

- `ARM9_PROFILE_ARM9TDMI`: ARM9TDMI Revision 3, Arm architecture v4T
- `ARM9_PROFILE_ARM946ES`: ARM946E-S r1p1 / ARM9E-S Revision 1, Arm architecture v5TE

The repository is in its specification and infrastructure phase. It does **not** yet
claim ISA completeness, cycle accuracy, or ARM946E-S memory-system completeness.
Feature status and evidence will be tracked in `docs/ACCURACY.md`; authoritative
source selection and file hashes are recorded in `docs/SOURCES.md`; cycle-table
coverage and source-conflict resolutions are recorded in `docs/TIMING.md`.

Reference manuals are downloaded for local research into the ignored `.reference/`
directory. Copyrighted manuals are not part of this repository.
