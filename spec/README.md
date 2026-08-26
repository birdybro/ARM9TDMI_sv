# Engineering Specification Database

`spec/` is the machine-readable source of requirements. Documentation establishes
the expected behavior, tests name requirement IDs, and RTL is not promoted to
`VERIFIED` until those tests pass cycle-by-cycle where timing is observable.

## Layout

- `sources.json`: exact source identities and hashes
- `catalog.json`: required specification domains and research completeness
- `requirements/*.json`: normative behavior requirements
- `timing/*.json`: cycle/bus timing rows with one traceable ID per qualification
- `schema.json`: format contract
- `../tools/validate_spec.py`: dependency-free structural and cross-reference checks

Requirement status values match `docs/ACCURACY.md`:

- `VERIFIED`
- `IMPLEMENTED_NOT_FULLY_VERIFIED`
- `PARTIAL`
- `UNSPECIFIED_BY_PUBLIC_SOURCE`
- `NOT_IMPLEMENTED`

An empty or `PLANNED` catalog domain is an explicit coverage gap, not an implicit
claim. Every source-backed requirement must contain at least one precise source
locator. Architecture-wide statements use `COMMON`; profile-specific behavior uses
`ARM9TDMI` or `ARM946ES` ID prefixes.

Tests refer to requirements using a machine-readable `requirement_ids` attribute or
an adjacent `REQ:` annotation. The traceability checker will reject unknown IDs.
