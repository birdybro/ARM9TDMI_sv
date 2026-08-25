# Authoritative Sources

This index records the evidence used to derive requirements. Public manuals are
downloaded only into the ignored `.reference/` directory for local engineering
analysis. The repository contains citations, concise derived facts, and hashes, not
copies of the manuals.

Retrieval date for the files below: 2026-08-25. SHA-256 values identify the exact
files studied, because Arm's stable documentation pages can later serve updated
assets under the same document number.

## Selected processor revisions

The ARM9TDMI profile targets **ARM9TDMI Revision 3**. Arm's current public
documentation catalog exposes DDI 0180A as the sole/latest DDI 0180 version and
labels it Rev 3. DDI 0168A (Rev 2) and DDI 0091A (Rev 0) are retained only for
revision comparison.

The ARM946E-S profile targets **ARM946E-S r1p1** as documented by DDI 0201D,
the newest English DDI 0201 revision in Arm's public catalog. Its CPU core is
**ARM9E-S Revision 1**, DDI 0165B. The r1p1 errata list is normative wherever it
describes silicon behavior that differs from the TRM.

## Source register

| Key | Title and revision | Document date | Official source | Local SHA-256 | Primary dependencies |
|---|---|---:|---|---|---|
| `DDI0180A` | ARM9TDMI Technical Reference Manual, Rev 3 | 2000-03 | [Arm documentation](https://developer.arm.com/documentation/ddi0180/a) | `38fc101a671518a0361271354fd402e9df4ebcbab1e4d0b865c69cc1c32adf44` | ARM9TDMI pipeline, Harvard interface, interlocks, cycle tables, multiplier termination, coprocessor, debug/JTAG, AC requirements |
| `DDI0201D` | ARM946E-S Technical Reference Manual, r1p1 | 2007-04-17 | [Arm documentation](https://developer.arm.com/documentation/ddi0201/d) | `fb45e13849688dcb8165cdf1c5ce0849492a64712ac5f094eecc23955a6d043f` | ARM946E-S profile, CP15, MPU, caches, TCM, write buffer, AHB BIU, external coprocessor, debug, ETM-facing interface, AC requirements |
| `DDI0165B` | ARM9E-S Technical Reference Manual, Rev 1 | 2000-09-12 | [Arm documentation](https://developer.arm.com/documentation/ddi0165/b) | `21db45eb339489ce7543e6d63c4ea0db3b6749152e9a51416766246791a0b03f` | ARM9E-S pipeline, ARMv5TE implementation, instruction timings, hazards, exception and interrupt timing, core memory/coprocessor/debug interfaces |
| `DDI0100I` | ARM Architecture Reference Manual, issue I | 2005-07 | [Arm documentation](https://developer.arm.com/documentation/ddi0100/i) | `c441eb7f981f3beb5ad901716808cd54d86e9b41aa68b42a2ce9701831b0b7ea` | ARMv4T and ARMv5TE programmer-visible architecture and instruction semantics |
| `IHI0011A` | AMBA Specification, Rev 2.0, issue A | 1999-05-13 | [Arm documentation](https://developer.arm.com/documentation/ihi0011/a) | `3e2876c47662461726b97f92e6680e6488ebac231a1efecf005a34e6179bdecf` | AMBA 2 AHB protocol and assertions |
| `ARM946-PRDC-000592-5.0` | ARM946E-S r1p1 Errata List, issue 5.0 | 2007-03-12 | [Arm errata PDF](https://documentation-service.arm.com/static/5ed4c52cca06a95ce53f91ae) | `8d43b1f1e99a38cf81aa99acc3c30a5c768291ca2cf6608759bc80e68cd134e0` | r1p1 deviations, affected conditions, and revision-specific tests |
| `DDI0157G` | ETM9 Technical Reference Manual, r2p2 | 2002-08-20 | [Arm document PDF](https://documentation-service.arm.com/static/5e8e2b3f88295d1e18d38253) | `78c49e5ff3cf70c96fd4d60339b8b9d3a097deca46a430d03558e76206a72fa3` | Context for ARM946E-S processor-side ETM9 interface; ETM9 itself remains a separate macrocell |
| `IHI0014Q` | Embedded Trace Macrocell Architecture Specification, issue Q | 2011-09-23 | [Arm document PDF](https://documentation-service.arm.com/static/5f90158b4966cd7c95fd5b5e) | `8093a1e74509a30fbc96ff0a70d4e61d6af6022a85f6d728d35ceb33add9ab8b` | ETM protocol/revision context; only processor-side behavior applicable to ARM946E-S is in implementation scope |
| `DDI0168A` | ARM9TDMI Technical Reference Manual, Rev 2 | 1999-07 | [Arm documentation](https://developer.arm.com/documentation/ddi0168/a) | `a9a90f342788b2f42deab696e460a6ca21946613ef7a330bd8e38fcd2251ab12` | Historical comparison against selected Rev 3 |
| `DDI0091A` | ARM9TDMI Technical Reference Manual, Rev 0 | 1998-07-21 | [Arm documentation](https://developer.arm.com/documentation/ddi0091/a) | `317625c0bbd73d6f4307d5897990871e538e95af5bfa34d8a6c9781ae70df73a` | Historical comparison against selected Rev 3 |

## Evidence precedence

1. The directly applicable processor TRM and its exact revision's errata.
2. The ARM9E-S core TRM for behavior delegated to that core by DDI 0201D.
3. The architecture manual for behavior not made implementation-specific by a TRM.
4. The AMBA or ETM architecture specification for protocol-level behavior.
5. Older processor revisions only to identify changes, never to override the selected
   revision silently.

Every normative requirement in `spec/` must cite a source key and a precise section,
table, figure, or page. Secondary implementations can help find questions but cannot
establish timing requirements.

## Source limitations and open research

- IEEE 1149.1 is not freely redistributed. The processor TRMs reproduce the portions
  and TAP behavior needed for their public debug interfaces; no access control will be
  bypassed to obtain the full IEEE standard.
- Confidential integration manuals, implementation guides, licensed RTL, and test
  vectors are out of scope unless Arm makes them publicly and lawfully available.
- Physical propagation delays are implementation-technology dependent. Published
  interface edge relationships and setup/hold requirements will be captured separately
  from synthesizable cycle behavior.
- Errata research remains active. New authoritative revisions or correction notices will
  be added with their own hashes rather than replacing historical entries silently.
