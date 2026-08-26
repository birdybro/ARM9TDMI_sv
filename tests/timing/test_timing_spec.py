import json
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


def load_timing(name: str) -> dict:
    with (ROOT / "spec" / "timing" / name).open(encoding="utf-8") as handle:
        return json.load(handle)


def row_by_id(table: dict, row_id: str) -> dict:
    return next(row for row in table["rows"] if row["id"] == row_id)


class TimingSpecificationTest(unittest.TestCase):
    def test_arm9tdmi_summary_has_every_documented_qualification(self) -> None:
        # REQ: ARM9TDMI-TIMING-TABLE-001
        table = load_timing("arm9tdmi_instruction_cycles.json")
        self.assertEqual(len(table["rows"]), 29)
        self.assertEqual(len(table["multiplier_rules"]), 2)

    def test_arm9es_summary_has_every_documented_qualification(self) -> None:
        # REQ: ARM946ES-TIMING-TABLE-001
        table = load_timing("arm9es_instruction_cycles.json")
        self.assertEqual(len(table["rows"]), 52)
        self.assertNotIn("m", table["symbols"])

    def test_profiles_do_not_share_multiplier_timing_model(self) -> None:
        # REQ: ARM9TDMI-TIMING-MULTERM-001
        # REQ: ARM946ES-MULTIPLIER-001
        tdmi = load_timing("arm9tdmi_instruction_cycles.json")
        arm9e = load_timing("arm9es_instruction_cycles.json")
        self.assertIn("m", tdmi["symbols"])
        self.assertNotIn("m", arm9e["symbols"])

    def test_one_register_ldm_conflict_is_resolved_per_profile(self) -> None:
        # REQ: ARM9TDMI-TIMING-LDM-001
        # REQ: ARM946ES-TIMING-LDM-001
        tdmi = load_timing("arm9tdmi_instruction_cycles.json")
        arm9e = load_timing("arm9es_instruction_cycles.json")

        self.assertEqual(
            row_by_id(tdmi, "ARM9TDMI-TIMING-LDM-001")["data_bus"],
            "1S+1I",
        )
        self.assertEqual(
            row_by_id(arm9e, "ARM946ES-TIMING-LDM-001")["data_bus"],
            "1N+1I",
        )
        conflicts = {
            conflict["id"]: conflict for conflict in arm9e["source_conflicts"]
        }
        resolution = conflicts["ARM946ES-TIMING-LDM-DATABUS-001"]
        self.assertIn("Table 8-23", resolution["detailed_source"])
        self.assertIn("more specific", resolution["resolution"])


if __name__ == "__main__":
    unittest.main()
