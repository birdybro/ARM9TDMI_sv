# Architecture

The design uses two explicit configurations defined by `arm9_profile_pkg`:

| Property | ARM9TDMI profile | ARM946E-S profile |
|---|---|---|
| Target | ARM9TDMI Rev 3 | ARM946E-S r1p1 with ARM9E-S Rev 1 |
| Architecture | v4T | v5TE |
| Integer pipeline | five stages | five stages |
| Multiply timing | operand-dependent early termination | enhanced fixed class timing plus dependency interlocks |
| External memory | Harvard instruction/data core interface | cache/TCM/MPU/write-buffer subsystem and AMBA 2 AHB |
| System coprocessor | none | CP15 |
| ETM | no profile interface requirement | processor-side external ETM interface |

The package only establishes compile-time feature selection. It does not implement
the listed subsystems and must not be treated as a generic-core feature switch that
allows unsupported combinations. Original ARM946E-S macrocell configuration choices
such as cache and TCM sizes will be separate parameters constrained to documented
values.

Shared RTL is permitted only where the two manuals establish common behavior.
Profile-specific pipeline timing, instruction legality, multiplier behavior, memory
interfaces, and system features remain separate at their behavioral boundaries.

The common state layer currently contains mode-aware R0-R14 physical banking and a
CPSR/five-SPSR store. PSR reserved bits are masked according to the selected
architecture profile, so Q exists only for ARM946E-S. The status-register reset path
only initializes the fields the manuals define (Supervisor mode, I=1, F=1, T=0);
NZCV and Q deliberately have no reset assignment because their post-reset values are
documented as indeterminate.

Common ARM PSR-transfer decode and MRS/MSR execution are also explicit units. MSR
applies architecture-specific ARMv4T/v5TE allocated-bit masks before presenting a
write intent to the state store. DDI0100I Table A4-1 prints `PrivMask` as
`0x0000000F`, but the same section defines MSR as updating interrupt enables and
shows `CPSR_c` writing bit 7. The derived mask is therefore `0x000000DF`: I, F, and
M[4:0], with T excluded by `StateMask`. This documentary inconsistency and its
resolution are retained in `spec/requirements/msr_execute.json`.
