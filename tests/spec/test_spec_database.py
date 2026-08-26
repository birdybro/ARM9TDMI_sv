import unittest

from tools.validate_spec import validate


class SpecDatabaseTest(unittest.TestCase):
    def test_spec_database_is_structurally_valid(self) -> None:
        self.assertEqual(validate(), [])


if __name__ == "__main__":
    unittest.main()
