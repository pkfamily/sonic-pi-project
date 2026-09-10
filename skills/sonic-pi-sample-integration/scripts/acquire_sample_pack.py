#!/usr/bin/env python3
"""Safely download or unpack a sample archive without overwriting files."""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
from typing import BinaryIO
import urllib.parse
import urllib.request
import zipfile


CHUNK_SIZE = 1024 * 1024


class AcquisitionError(RuntimeError):
    """Raised when acquisition cannot be completed safely."""


def archive_member_path(name: str) -> PurePosixPath:
    normalized = name.replace("\\", "/")
    if "\x00" in normalized or re.match(r"^[A-Za-z]:", normalized):
        raise AcquisitionError(f"unsafe archive member: {name!r}")
    member = PurePosixPath(normalized)
    if member.is_absolute() or ".." in member.parts:
        raise AcquisitionError(f"unsafe archive member: {name!r}")
    return member


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(CHUNK_SIZE), b""):
            digest.update(chunk)
    return digest.hexdigest()


def copy_limited(source: BinaryIO, target: BinaryIO, max_bytes: int) -> int:
    total = 0
    while True:
        chunk = source.read(CHUNK_SIZE)
        if not chunk:
            return total
        total += len(chunk)
        if total > max_bytes:
            raise AcquisitionError(
                f"download exceeded configured limit of {max_bytes} bytes"
            )
        target.write(chunk)


def download(url: str, output: Path, max_bytes: int) -> None:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme.lower() != "https":
        raise AcquisitionError("downloads must use HTTPS")

    request = urllib.request.Request(
        url, headers={"User-Agent": "sonic-pi-sample-integration/1.0"}
    )
    try:
        with urllib.request.urlopen(request) as response:
            final_scheme = urllib.parse.urlparse(response.geturl()).scheme.lower()
            if final_scheme != "https":
                raise AcquisitionError("download redirected away from HTTPS")
            content_length = response.headers.get("Content-Length")
            if content_length and int(content_length) > max_bytes:
                raise AcquisitionError(
                    f"download is {content_length} bytes; limit is {max_bytes}"
                )
            with output.open("wb") as handle:
                copy_limited(response, handle, max_bytes)
    except AcquisitionError:
        raise
    except Exception as exc:
        raise AcquisitionError(f"download failed: {exc}") from exc


def safe_target(root: Path, member_name: str) -> Path:
    member = archive_member_path(member_name)
    target = root.joinpath(*member.parts)
    try:
        target.resolve().relative_to(root.resolve())
    except ValueError as exc:
        raise AcquisitionError(
            f"archive member escapes destination: {member_name!r}"
        ) from exc
    return target


def extract_zip(archive: Path, root: Path, max_bytes: int) -> None:
    with zipfile.ZipFile(archive) as source:
        infos = source.infolist()
        if sum(info.file_size for info in infos) > max_bytes:
            raise AcquisitionError("expanded ZIP exceeds configured size limit")
        seen: set[PurePosixPath] = set()
        for info in infos:
            member = archive_member_path(info.filename)
            if member in seen and not info.is_dir():
                raise AcquisitionError(f"duplicate archive member: {info.filename!r}")
            seen.add(member)
            mode = (info.external_attr >> 16) & 0o170000
            if mode == 0o120000:
                raise AcquisitionError(f"archive links are not allowed: {info.filename!r}")
            target = safe_target(root, info.filename)
            if info.is_dir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            target.parent.mkdir(parents=True, exist_ok=True)
            with source.open(info) as input_handle, target.open("xb") as output_handle:
                shutil.copyfileobj(input_handle, output_handle, CHUNK_SIZE)


def extract_tar(archive: Path, root: Path, max_bytes: int) -> None:
    with tarfile.open(archive, "r:*") as source:
        members = source.getmembers()
        if sum(member.size for member in members if member.isfile()) > max_bytes:
            raise AcquisitionError("expanded TAR exceeds configured size limit")
        seen: set[PurePosixPath] = set()
        for member_info in members:
            member = archive_member_path(member_info.name)
            if member in seen and not member_info.isdir():
                raise AcquisitionError(
                    f"duplicate archive member: {member_info.name!r}"
                )
            seen.add(member)
            if not (member_info.isfile() or member_info.isdir()):
                raise AcquisitionError(
                    "archive links and special files are not allowed: "
                    f"{member_info.name!r}"
                )
            target = safe_target(root, member_info.name)
            if member_info.isdir():
                target.mkdir(parents=True, exist_ok=True)
                continue
            input_handle = source.extractfile(member_info)
            if input_handle is None:
                raise AcquisitionError(
                    f"could not read archive member: {member_info.name!r}"
                )
            target.parent.mkdir(parents=True, exist_ok=True)
            with input_handle, target.open("xb") as output_handle:
                shutil.copyfileobj(input_handle, output_handle, CHUNK_SIZE)


def inspect_extracted_tree(root: Path, max_bytes: int) -> tuple[int, int]:
    file_count = 0
    total_bytes = 0
    for current_root, directories, files in os.walk(root, followlinks=False):
        current = Path(current_root)
        for entry_name in directories + files:
            entry = current / entry_name
            if entry.is_symlink():
                raise AcquisitionError(f"archive links are not allowed: {entry}")
        for file_name in files:
            entry = current / file_name
            if not entry.is_file():
                raise AcquisitionError(f"archive special files are not allowed: {entry}")
            file_count += 1
            total_bytes += entry.stat().st_size
            if total_bytes > max_bytes:
                raise AcquisitionError("expanded archive exceeds configured size limit")
    return file_count, total_bytes


def extract_with_bsdtar(archive: Path, root: Path, max_bytes: int) -> None:
    executable = shutil.which("bsdtar")
    if executable is None:
        raise AcquisitionError(
            "archive is not ZIP or TAR and bsdtar is unavailable (required for 7z)"
        )
    listing = subprocess.run(
        [executable, "-tf", str(archive)],
        capture_output=True,
        text=True,
        check=False,
    )
    if listing.returncode != 0:
        raise AcquisitionError(f"bsdtar could not list archive: {listing.stderr.strip()}")
    for member_name in listing.stdout.splitlines():
        archive_member_path(member_name)
    verbose_listing = subprocess.run(
        [executable, "-tvf", str(archive)],
        capture_output=True,
        text=True,
        check=False,
    )
    if verbose_listing.returncode != 0:
        raise AcquisitionError(
            f"bsdtar could not inspect archive types: {verbose_listing.stderr.strip()}"
        )
    for entry in verbose_listing.stdout.splitlines():
        if entry and entry[0] not in {"-", "d"}:
            raise AcquisitionError(
                f"archive links and special files are not allowed: {entry}"
            )
    result = subprocess.run(
        [
            executable,
            "-xf",
            str(archive),
            "-C",
            str(root),
            "--no-same-owner",
            "--no-same-permissions",
        ],
        capture_output=True,
        text=True,
        check=False,
    )
    if result.returncode != 0:
        raise AcquisitionError(f"bsdtar extraction failed: {result.stderr.strip()}")
    inspect_extracted_tree(root, max_bytes)


def extract_archive(archive: Path, root: Path, max_bytes: int) -> tuple[int, int]:
    if zipfile.is_zipfile(archive):
        extract_zip(archive, root, max_bytes)
    elif tarfile.is_tarfile(archive):
        extract_tar(archive, root, max_bytes)
    else:
        extract_with_bsdtar(archive, root, max_bytes)
    return inspect_extracted_tree(root, max_bytes)


def install_staged(staged: Path, destination: Path) -> None:
    entries = list(staged.iterdir())
    if not entries:
        raise AcquisitionError("archive contains no files")
    if destination.exists() and not destination.is_dir():
        raise AcquisitionError(f"destination is not a directory: {destination}")
    collisions = [entry.name for entry in entries if (destination / entry.name).exists()]
    if collisions:
        joined = ", ".join(sorted(collisions))
        raise AcquisitionError(f"destination collision; nothing installed: {joined}")

    destination.mkdir(parents=True, exist_ok=True)
    moved: list[Path] = []
    try:
        for entry in entries:
            target = destination / entry.name
            os.replace(entry, target)
            moved.append(target)
    except Exception:
        for target in reversed(moved):
            os.replace(target, staged / target.name)
        raise


def acquire(
    *,
    url: str | None,
    archive_path: Path | None,
    destination: Path,
    expected_sha256: str | None,
    accept_unverified: bool,
    max_bytes: int,
) -> dict[str, object]:
    if not expected_sha256 and not accept_unverified:
        raise AcquisitionError(
            "provide --sha256 or explicitly acknowledge the risk with --accept-unverified"
        )
    if expected_sha256 and not re.fullmatch(r"[0-9a-fA-F]{64}", expected_sha256):
        raise AcquisitionError("--sha256 must contain exactly 64 hexadecimal characters")
    if max_bytes <= 0:
        raise AcquisitionError("size limit must be positive")

    destination = destination.expanduser().resolve()
    destination.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(
        prefix=".sample-pack-", dir=str(destination.parent)
    ) as temporary_directory:
        temporary_root = Path(temporary_directory)
        if url:
            archive = temporary_root / "downloaded-archive"
            download(url, archive, max_bytes)
            source_label = url
        else:
            if archive_path is None:
                raise AcquisitionError("an archive source is required")
            archive = archive_path.expanduser().resolve()
            if not archive.is_file():
                raise AcquisitionError(f"archive does not exist: {archive}")
            if archive.stat().st_size > max_bytes:
                raise AcquisitionError("archive exceeds configured size limit")
            source_label = str(archive)

        actual_sha256 = sha256_file(archive)
        if expected_sha256 and actual_sha256.lower() != expected_sha256.lower():
            raise AcquisitionError(
                f"SHA-256 mismatch: expected {expected_sha256.lower()}, got {actual_sha256}"
            )

        staged = temporary_root / "extracted"
        staged.mkdir()
        file_count, expanded_bytes = extract_archive(archive, staged, max_bytes)
        install_staged(staged, destination)

    return {
        "source": source_label,
        "archive_sha256": actual_sha256,
        "checksum_verified": bool(expected_sha256),
        "destination": str(destination),
        "files_installed": file_count,
        "expanded_bytes": expanded_bytes,
    }


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Safely download, verify, and extract a sample pack."
    )
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument("--url", help="HTTPS archive URL")
    source.add_argument("--archive", type=Path, help="existing local archive")
    parser.add_argument("--destination", type=Path, required=True)
    verification = parser.add_mutually_exclusive_group(required=True)
    verification.add_argument("--sha256", help="expected archive SHA-256")
    verification.add_argument(
        "--accept-unverified",
        action="store_true",
        help="continue without an independently published checksum",
    )
    parser.add_argument(
        "--max-mib", type=int, default=2048, help="maximum archive and expanded size"
    )
    parser.add_argument("--json", action="store_true", help="emit JSON output")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        result = acquire(
            url=args.url,
            archive_path=args.archive,
            destination=args.destination,
            expected_sha256=args.sha256,
            accept_unverified=args.accept_unverified,
            max_bytes=args.max_mib * 1024 * 1024,
        )
    except (AcquisitionError, OSError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2

    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        verification = "verified" if result["checksum_verified"] else "unverified"
        print(f"Installed {result['files_installed']} files in {result['destination']}")
        print(f"Archive SHA-256 ({verification}): {result['archive_sha256']}")
        print(f"Expanded bytes: {result['expanded_bytes']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
