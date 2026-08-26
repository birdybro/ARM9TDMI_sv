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
