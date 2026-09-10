from __future__ import annotations

import hashlib
from pathlib import Path
import sys
import tarfile
import tempfile
import unittest
import zipfile


SCRIPT_DIR = Path(__file__).resolve().parents[1] / "scripts"
sys.path.insert(0, str(SCRIPT_DIR))

from acquire_sample_pack import AcquisitionError, acquire  # noqa: E402


class AcquireSamplePackTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)

    def tearDown(self) -> None:
        self.temporary.cleanup()

    def create_zip(self, members: dict[str, bytes]) -> Path:
        archive = self.root / "pack.zip"
        with zipfile.ZipFile(archive, "w") as output:
            for name, content in members.items():
                output.writestr(name, content)
        return archive

    def run_acquire(
        self, archive: Path, destination: Path, **overrides: object
    ) -> dict[str, object]:
        options = {
            "url": None,
            "archive_path": archive,
            "destination": destination,
            "expected_sha256": hashlib.sha256(archive.read_bytes()).hexdigest(),
            "accept_unverified": False,
            "max_bytes": 1024 * 1024,
        }
        options.update(overrides)
        return acquire(**options)

    def test_extracts_verified_zip(self) -> None:
        archive = self.create_zip({"Instrument/samples/note.wav": b"audio"})
        destination = self.root / "installed"
        result = self.run_acquire(archive, destination)
        installed = destination / "Instrument/samples/note.wav"
        self.assertEqual(installed.read_bytes(), b"audio")
        self.assertTrue(result["checksum_verified"])
        self.assertEqual(result["files_installed"], 1)

    def test_requires_checksum_acknowledgement(self) -> None:
        archive = self.create_zip({"note.wav": b"audio"})
        with self.assertRaisesRegex(AcquisitionError, "--sha256"):
            self.run_acquire(
                archive,
                self.root / "installed",
                expected_sha256=None,
                accept_unverified=False,
            )

    def test_rejects_checksum_mismatch(self) -> None:
        archive = self.create_zip({"note.wav": b"audio"})
        with self.assertRaisesRegex(AcquisitionError, "SHA-256 mismatch"):
            self.run_acquire(
                archive, self.root / "installed", expected_sha256="0" * 64
            )

    def test_rejects_path_traversal(self) -> None:
        archive = self.create_zip({"../outside.wav": b"audio"})
        with self.assertRaisesRegex(AcquisitionError, "unsafe archive member"):
            self.run_acquire(archive, self.root / "installed")
        self.assertFalse((self.root / "outside.wav").exists())

    def test_rejects_tar_links(self) -> None:
        archive = self.root / "pack.tar"
        with tarfile.open(archive, "w") as output:
            link = tarfile.TarInfo("linked.wav")
            link.type = tarfile.SYMTYPE
            link.linkname = "/tmp/outside.wav"
            output.addfile(link)
        with self.assertRaisesRegex(AcquisitionError, "links and special files"):
            self.run_acquire(archive, self.root / "installed")

    def test_rejects_expanded_size_limit(self) -> None:
        archive = self.root / "compressed-pack.zip"
        with zipfile.ZipFile(archive, "w", compression=zipfile.ZIP_DEFLATED) as output:
            output.writestr("large.wav", b"x" * 10_000)
        with self.assertRaisesRegex(AcquisitionError, "expanded ZIP"):
            self.run_acquire(archive, self.root / "installed", max_bytes=1000)

    def test_rejects_collision_without_partial_install(self) -> None:
        archive = self.create_zip(
            {"Instrument/new.wav": b"new", "Other/ok.wav": b"ok"}
        )
        destination = self.root / "installed"
        (destination / "Instrument").mkdir(parents=True)
        existing = destination / "Instrument/original.wav"
        existing.write_bytes(b"original")
        with self.assertRaisesRegex(AcquisitionError, "destination collision"):
            self.run_acquire(archive, destination)
        self.assertFalse((destination / "Other").exists())
        self.assertEqual(existing.read_bytes(), b"original")


if __name__ == "__main__":
    unittest.main()
