# Accuracy and Coverage

Last updated: 2026-08-25

The first common architectural-state primitives now exist, but there is no integrated
processor core yet. Nothing is claimed cycle-accurate or ISA complete. The source and
traceability database is validated, but specification coverage is still being
expanded.

Status vocabulary:

- **VERIFIED**
- **IMPLEMENTED, NOT YET FULLY VERIFIED**
- **PARTIAL**
- **UNSPECIFIED BY PUBLIC SOURCE**
- **NOT IMPLEMENTED**

## Coverage matrix

| Domain | Specification | RTL | Verification |
|---|---|---|---|
| Profile/revision selection | BASELINED | VERIFIED configuration package | VERIFIED for both profiles |
| ARM programmer-visible state | PARTIAL | PARTIAL (R0-R14, CPSR/SPSR banks, basic PC addressing, ARM9TDMI stored-PC selection, profile-specific ARM LDR/LDM-to-PC completion, block-transfer bank/exception-return intents) | VERIFIED bank selection, PSR masks, reset fields, ordinary PC reads/writes, BX/LDR/LDM targets, ARM946E-S CP15 loading-TBIT control behavior, ARM9TDMI STR/STM R15 value, and LDM/STM S-bit privilege/exception-return classification; ARM946E-S stored-PC choice remains unspecified by reviewed public sources |
| ARM condition evaluation | BASELINED | VERIFIED | VERIFIED (256 combinations) |
| ARM instruction set | PARTIAL | PARTIAL (non-PC data processing, branch execute, common multiply execute, ARMv5TE DSP multiply execute, CLZ, saturating arithmetic, SWI, MRS/MSR decode, Addressing Modes 2/3/4, condition-gated LDM/STM descriptors, profile-separated LDRD/STRD paths, SWP/SWPB decode/preparation/completion, and common single/miscellaneous transfer paths) | VERIFIED ALU/shifter/immediate/decode integration, branches, multiply/DSP/CLZ/saturating/SWI side-effect intents, exhaustive MRS/MSR encoding classification, Addressing Modes 2/3/4, LDM/STM register/range/bank/writeback preparation, ARM946E-S LDRD/STRD paths with ARM9TDMI exclusion, exhaustive common SWP/SWPB decode, atomic descriptor, returned-data, and precise-abort intents, common single/miscellaneous request and completion intents, and load formatting; PSR-transfer execution/timing, block-transfer sequencing/completion, swap bus sequencing, external memory interfaces, cycle timing, and other classes not implemented |
| Thumb instruction set | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Exceptions and aborts | PARTIAL | PARTIAL (architectural entry effects/priority plus single/miscellaneous/doubleword/swap and LDM-PC precise Data Abort completion intent) | VERIFIED fixed simultaneous-exception priority, I/F interrupt masking, mode/vector/SPSR/LR/CPSR entry intents for all seven exceptions, profile-specific high-vector selection, implemented load destination preservation/uncertainty, base-restored writeback suppression, SWP/SWPB cancellation, and LDM PC/CPSR-restore suppression; recognition points, pipeline sequencing, general LDM destination uncertainty, and timing not implemented |
| Five-stage pipelines | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Instruction cycle summary tables | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Detailed hazards/interlocks | PARTIAL | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM9TDMI multiplier termination | BASELINED | VERIFIED latency classifier | VERIFIED signed/unsigned class boundaries and cycle equations |
| ARM946E-S multiplier timing | BASELINED | VERIFIED class/interlock classifier | VERIFIED fixed class, flag-setting, and qualified dependency cycles |
| ARM9TDMI Harvard interface | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| External coprocessor protocol | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S CP15 | PARTIAL | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S protection unit | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S caches | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S TCM interfaces | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S write buffer | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S AHB interface | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Debug/JTAG/EmbeddedICE | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM946E-S ETM-facing interface | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Physical AC constraints/checks | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Formal verification | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Synthesis | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |

The machine-readable details in `spec/catalog.json` are authoritative for research
completeness. Requirement-level implementation and verification statuses live beside
each requirement so coverage reports can be generated rather than hand-counted.
