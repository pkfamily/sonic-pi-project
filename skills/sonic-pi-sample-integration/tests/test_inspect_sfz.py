from __future__ import annotations

import json
import math
from pathlib import Path
import sys
import tempfile
import unittest


SCRIPT_DIR = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))

from inspect_sfz import SfzError, inspect, midi_note, parse_sfz  # noqa: E402


class InspectSfzTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def write_fixture(self, text: str) -> Path:
        sfz = self.root / "instrument.sfz"
        sfz.write_text(text, encoding="utf-8")
        return sfz

    def test_note_parser_supports_names_flats_and_numbers(self) -> None:
        self.assertEqual(midi_note("C4"), 60)
        self.assertEqual(midi_note("C#4"), 61)
        self.assertEqual(midi_note("Db4"), 61)
        self.assertEqual(midi_note("69"), 69)

    def test_inherits_scopes_velocity_and_random_regions(self) -> None:
        sample_dir = self.root / "Samples With Spaces"
        sample_dir.mkdir()
        (sample_dir / "B3 soft.wav").write_bytes(b"audio")
        sfz = self.write_fixture(
            """
            <control> default_path=Samples With Spaces/
            <global> ampeg_release=1.1
            <group> lokey=A3 hikey=B3 hivel=92 pitch_keycenter=B3
            <region> lorand=0 hirand=0.5 sample=B3 soft.wav
            <region> lorand=0.5 hirand=1 sample=B3 soft.wav
            """
        )
        results = inspect(sfz, [midi_note("A3")], 64)
        self.assertEqual(len(results), 2)
        self.assertEqual(results[0]["source_note"], "B3")
        self.assertEqual(results[0]["semitone_shift"], -2)
        self.assertAlmostEqual(
            results[0]["sonic_pi_rate"], math.pow(2, -2 / 12)
        )
        self.assertTrue(results[0]["sample_exists"])
        self.assertEqual(results[1]["random_range"], [0.5, 1.0])

    def test_filters_velocity_layers(self) -> None:
        (self.root / "soft.wav").write_bytes(b"soft")
        (self.root / "firm.wav").write_bytes(b"firm")
        sfz = self.write_fixture(
            """
            <group> key=C4 hivel=92
            <region> sample=soft.wav
            <group> key=C4 lovel=93
            <region> sample=firm.wav
            """
        )
        soft = inspect(sfz, [60], 40)
        firm = inspect(sfz, [60], 110)
        self.assertEqual([entry["sample"] for entry in soft], ["soft.wav"])
        self.assertEqual([entry["sample"] for entry in firm], ["firm.wav"])

    def test_reports_sequence_metadata_and_missing_sample(self) -> None:
        sfz = self.write_fixture(
            "<region> key=D4 seq_length=4 seq_position=2 sample=missing.wav"
        )
        result = inspect(sfz, [62], None)[0]
        self.assertEqual(result["sequence"], {"length": 4, "position": 2})
        self.assertFalse(result["sample_exists"])

    def test_rejects_include_directive(self) -> None:
        sfz = self.write_fixture('#include "regions.sfz"')
        with self.assertRaisesRegex(SfzError, "#include"):
            parse_sfz(sfz)

    def test_json_result_is_serializable(self) -> None:
        (self.root / "note.wav").write_bytes(b"audio")
        sfz = self.write_fixture("<region> key=60 sample=note.wav")
        json.dumps(inspect(sfz, [60], None))


if __name__ == "__main__":
    unittest.main()
