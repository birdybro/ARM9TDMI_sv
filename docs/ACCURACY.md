# Accuracy and Coverage

Last updated: 2026-08-25

No processor RTL exists at this milestone. Nothing is claimed cycle-accurate or ISA
complete. The source and traceability database is validated, but specification
coverage is still being expanded.

Status vocabulary:

- **VERIFIED**
- **IMPLEMENTED, NOT YET FULLY VERIFIED**
- **PARTIAL**
- **UNSPECIFIED BY PUBLIC SOURCE**
- **NOT IMPLEMENTED**

## Coverage matrix

| Domain | Specification | RTL | Verification |
|---|---|---|---|
| Profile/revision selection | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM programmer-visible state | PARTIAL | PARTIAL (R0-R14 banking) | VERIFIED bank selection; CPSR/SPSR/PC not implemented |
| ARM condition evaluation | BASELINED | VERIFIED | VERIFIED (256 combinations) |
| ARM instruction set | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Thumb instruction set | PLANNED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Exceptions and aborts | PARTIAL | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Five-stage pipelines | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Instruction cycle summary tables | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
| Detailed hazards/interlocks | PARTIAL | NOT IMPLEMENTED | NOT IMPLEMENTED |
| ARM9TDMI multiplier termination | BASELINED | NOT IMPLEMENTED | NOT IMPLEMENTED |
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
