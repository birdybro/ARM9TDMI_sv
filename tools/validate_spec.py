#!/usr/bin/env python3
"""Validate the engineering specification database without third-party packages."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
SPEC = ROOT / "spec"

ID_RE = re.compile(r"^(COMMON|ARM9TDMI|ARM946ES)-[A-Z0-9-]+-[0-9]{3}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
PROFILE_VALUES = {"ARM9_PROFILE_ARM9TDMI", "ARM9_PROFILE_ARM946ES"}
STATUS_VALUES = {
    "VERIFIED",
    "IMPLEMENTED_NOT_FULLY_VERIFIED",
    "PARTIAL",
    "UNSPECIFIED_BY_PUBLIC_SOURCE",
    "NOT_IMPLEMENTED",
}


def load_json(path: Path, errors: list[str]) -> Any:
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path.relative_to(ROOT)}: {exc}")
        return None


def require(condition: bool, errors: list[str], message: str) -> None:
    if not condition:
        errors.append(message)


def validate_status_block(
    block: Any, kind: str, context: str, errors: list[str]
) -> None:
    require(isinstance(block, dict), errors, f"{context}: missing {kind} block")
    if not isinstance(block, dict):
        return
    require(
        block.get("status") in STATUS_VALUES,
        errors,
        f"{context}: invalid {kind} status {block.get('status')!r}",
    )
    list_key = "rtl" if kind == "implementation" else "tests"
    require(
        isinstance(block.get(list_key), list),
        errors,
        f"{context}: {kind}.{list_key} must be a list",
    )
    if block.get("status") == "VERIFIED":
        require(
            bool(block.get(list_key)),
            errors,
            f"{context}: VERIFIED {kind} requires at least one {list_key} path",
        )


def validate_source_refs(
    refs: Any, source_keys: set[str], context: str, errors: list[str]
) -> None:
    require(
        isinstance(refs, list) and bool(refs),
        errors,
        f"{context}: source_refs must be a nonempty list",
    )
    if not isinstance(refs, list):
        return
    for index, ref in enumerate(refs):
        ref_context = f"{context}: source_refs[{index}]"
        require(isinstance(ref, dict), errors, f"{ref_context} must be an object")
        if not isinstance(ref, dict):
            continue
        require(
            ref.get("source") in source_keys,
            errors,
            f"{ref_context}: unknown source {ref.get('source')!r}",
        )
        require(
            isinstance(ref.get("locator"), str) and bool(ref.get("locator").strip()),
            errors,
            f"{ref_context}: locator must be nonempty",
        )


def validate_requirement(
    req: Any,
    context: str,
    source_keys: set[str],
    categories: set[str],
    ids: set[str],
    categories_seen: set[str],
    errors: list[str],
) -> None:
    require(isinstance(req, dict), errors, f"{context}: requirement must be an object")
    if not isinstance(req, dict):
        return
    req_id = req.get("id")
    require(
        isinstance(req_id, str) and bool(ID_RE.fullmatch(req_id)),
        errors,
        f"{context}: malformed requirement id {req_id!r}",
    )
    if isinstance(req_id, str):
        require(req_id not in ids, errors, f"{context}: duplicate requirement id {req_id}")
        ids.add(req_id)
    profiles = req.get("profiles")
    require(
        isinstance(profiles, list)
        and bool(profiles)
        and len(profiles) == len(set(profiles))
        and set(profiles).issubset(PROFILE_VALUES),
        errors,
        f"{context}: invalid profiles {profiles!r}",
    )
    category = req.get("category")
    require(
        category in categories,
        errors,
        f"{context}: unknown category {category!r}",
    )
    if category in categories:
        categories_seen.add(category)
    statement = req.get("statement")
    require(
        isinstance(statement, str) and bool(statement.strip()),
        errors,
        f"{context}: statement must be nonempty",
    )
    validate_source_refs(req.get("source_refs"), source_keys, context, errors)
    validate_status_block(req.get("implementation"), "implementation", context, errors)
    validate_status_block(req.get("verification"), "verification", context, errors)


def validate() -> list[str]:
    errors: list[str] = []

    sources_doc = load_json(SPEC / "sources.json", errors)
    catalog_doc = load_json(SPEC / "catalog.json", errors)
    load_json(SPEC / "schema.json", errors)
    if not isinstance(sources_doc, dict) or not isinstance(catalog_doc, dict):
        return errors

    require(sources_doc.get("schema_version") == 1, errors, "sources.json: schema_version must be 1")
    source_keys: set[str] = set()
    for index, source in enumerate(sources_doc.get("sources", [])):
        context = f"spec/sources.json: sources[{index}]"
        require(isinstance(source, dict), errors, f"{context} must be an object")
        if not isinstance(source, dict):
            continue
        key = source.get("key")
        require(isinstance(key, str) and bool(key), errors, f"{context}: key is required")
        if isinstance(key, str):
            require(key not in source_keys, errors, f"{context}: duplicate source key {key}")
            source_keys.add(key)
        require(
            isinstance(source.get("url"), str)
            and source["url"].startswith("https://"),
            errors,
            f"{context}: official HTTPS url is required",
        )
        require(
            isinstance(source.get("sha256"), str)
            and bool(SHA256_RE.fullmatch(source["sha256"])),
            errors,
            f"{context}: sha256 must contain 64 lowercase hexadecimal digits",
        )

    research_values = set(catalog_doc.get("research_status_values", []))
    categories: set[str] = set()
    baselined_categories: set[str] = set()
    for index, category in enumerate(catalog_doc.get("categories", [])):
        context = f"spec/catalog.json: categories[{index}]"
        require(isinstance(category, dict), errors, f"{context} must be an object")
        if not isinstance(category, dict):
            continue
        category_id = category.get("id")
        require(
            isinstance(category_id, str) and bool(category_id),
            errors,
            f"{context}: id is required",
        )
        if isinstance(category_id, str):
            require(category_id not in categories, errors, f"{context}: duplicate category {category_id}")
            categories.add(category_id)
            if category.get("research_status") in {"BASELINED", "COMPLETE"}:
                baselined_categories.add(category_id)
        require(
            category.get("research_status") in research_values,
            errors,
            f"{context}: invalid research_status {category.get('research_status')!r}",
        )

    ids: set[str] = set()
    categories_seen: set[str] = set()
    requirement_files = sorted((SPEC / "requirements").glob("*.json"))
    require(bool(requirement_files), errors, "spec/requirements: no requirement files")
    for path in requirement_files:
        doc = load_json(path, errors)
        if not isinstance(doc, dict):
            continue
        require(doc.get("schema_version") == 1, errors, f"{path.relative_to(ROOT)}: schema_version must be 1")
        requirements = doc.get("requirements")
        require(isinstance(requirements, list), errors, f"{path.relative_to(ROOT)}: requirements must be a list")
        if not isinstance(requirements, list):
            continue
        for index, req in enumerate(requirements):
            validate_requirement(
                req,
                f"{path.relative_to(ROOT)}: requirements[{index}]",
                source_keys,
                categories,
                ids,
                categories_seen,
                errors,
            )

    timing_files = sorted((SPEC / "timing").glob("*.json"))
    require(bool(timing_files), errors, "spec/timing: no timing files")
    for path in timing_files:
        doc = load_json(path, errors)
        context = str(path.relative_to(ROOT))
        if not isinstance(doc, dict):
            continue
        require(doc.get("schema_version") == 1, errors, f"{context}: schema_version must be 1")
        table_id = doc.get("table_id")
        require(
            isinstance(table_id, str) and bool(ID_RE.fullmatch(table_id)),
            errors,
            f"{context}: malformed table_id {table_id!r}",
        )
        if isinstance(table_id, str):
            require(table_id not in ids, errors, f"{context}: duplicate requirement id {table_id}")
            ids.add(table_id)
        category = doc.get("category")
        require(category in categories, errors, f"{context}: unknown category {category!r}")
        if category in categories:
            categories_seen.add(category)
        profiles = doc.get("profiles")
        require(
            isinstance(profiles, list) and bool(profiles) and set(profiles).issubset(PROFILE_VALUES),
            errors,
            f"{context}: invalid profiles {profiles!r}",
        )
        validate_source_refs(doc.get("source_refs"), source_keys, context, errors)
        validate_status_block(doc.get("implementation"), "implementation", context, errors)
        validate_status_block(doc.get("verification"), "verification", context, errors)
        rows = doc.get("rows")
        require(isinstance(rows, list) and bool(rows), errors, f"{context}: rows must be nonempty")
        if isinstance(rows, list):
            for index, row in enumerate(rows):
                row_context = f"{context}: rows[{index}]"
                require(isinstance(row, dict), errors, f"{row_context} must be an object")
                if not isinstance(row, dict):
                    continue
                row_id = row.get("id")
                require(
                    isinstance(row_id, str) and bool(ID_RE.fullmatch(row_id)),
                    errors,
                    f"{row_context}: malformed id {row_id!r}",
                )
                if isinstance(row_id, str):
                    require(row_id not in ids, errors, f"{row_context}: duplicate requirement id {row_id}")
                    ids.add(row_id)
                for key in ("operation", "qualification", "cycles", "instruction_bus", "data_bus"):
                    require(
                        isinstance(row.get(key), str) and bool(row[key].strip()),
                        errors,
                        f"{row_context}: {key} must be nonempty",
                    )
        for index, rule in enumerate(doc.get("multiplier_rules", [])):
            rule_context = f"{context}: multiplier_rules[{index}]"
            rule_id = rule.get("id") if isinstance(rule, dict) else None
            require(
                isinstance(rule_id, str) and bool(ID_RE.fullmatch(rule_id)),
                errors,
                f"{rule_context}: malformed id {rule_id!r}",
            )
            if isinstance(rule_id, str):
                require(rule_id not in ids, errors, f"{rule_context}: duplicate requirement id {rule_id}")
                ids.add(rule_id)

    missing_baselines = sorted(baselined_categories - categories_seen)
    require(
        not missing_baselines,
        errors,
        "catalog categories marked BASELINED/COMPLETE have no requirements: "
        + ", ".join(missing_baselines),
    )

    trace_pattern = re.compile(r"(?:REQ:\s*|requirement_ids\s*=\s*[^\n]*?)(ARM(?:9TDMI|946ES)-[A-Z0-9-]+-[0-9]{3}|COMMON-[A-Z0-9-]+-[0-9]{3})")
    for path in sorted((ROOT / "tests").rglob("*")):
        if not path.is_file() or path.suffix not in {".py", ".sv", ".json", ".yaml", ".yml"}:
            continue
        text = path.read_text(encoding="utf-8")
        for match in trace_pattern.finditer(text):
            require(
                match.group(1) in ids,
                errors,
                f"{path.relative_to(ROOT)}: unknown traced requirement {match.group(1)}",
            )

    return errors


def main() -> int:
    errors = validate()
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1
    print("Specification database valid")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
