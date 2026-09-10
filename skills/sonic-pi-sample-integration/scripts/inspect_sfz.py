#!/usr/bin/env python3
"""Inspect SFZ regions and calculate mappings for Sonic Pi target notes."""

from __future__ import annotations

import argparse
import json
import math
from pathlib import Path
import re
import sys
from typing import Any


class SfzError(RuntimeError):
    """Raised when an SFZ cannot be inspected reliably."""


NOTE_OFFSETS = {"C": 0, "D": 2, "E": 4, "F": 5, "G": 7, "A": 9, "B": 11}
SHARP_NAMES = (
    "C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"
)
MARKER_RE = re.compile(
    r"<(?P<header>control|global|group|region)>|"
    r"(?P<opcode>[A-Za-z][A-Za-z0-9_]*)=",
    re.I,
)


def midi_note(value: str | int) -> int:
    text = str(value).strip()
    if isinstance(value, int) or re.fullmatch(r"-?\d+", text):
        number = int(value)
    else:
        match = re.fullmatch(r"([A-Ga-g])([#b]?)(-?\d+)", text)
        if not match:
            raise SfzError(f"invalid note value: {value!r}")
        letter, accidental, octave_text = match.groups()
        number = (int(octave_text) + 1) * 12 + NOTE_OFFSETS[letter.upper()]
        if accidental == "#":
            number += 1
        elif accidental == "b":
            number -= 1
    if not 0 <= number <= 127:
        raise SfzError(f"MIDI note is outside 0-127: {value!r}")
    return number


def note_name(number: int) -> str:
    return f"{SHARP_NAMES[number % 12]}{(number // 12) - 1}"


def strip_comments(text: str) -> str:
    return "\n".join(line.split("//", 1)[0] for line in text.splitlines())


def parse_sfz(path: Path) -> list[dict[str, str]]:
    try:
        raw_text = path.read_text(encoding="utf-8-sig")
    except (OSError, UnicodeError) as exc:
        raise SfzError(f"could not read SFZ: {exc}") from exc
    if re.search(
        r"^\s*#include\b", raw_text, flags=re.MULTILINE | re.IGNORECASE
    ):
        raise SfzError("#include directives are not supported; flatten the SFZ first")

    text = strip_comments(raw_text)
    markers = list(MARKER_RE.finditer(text))
    control: dict[str, str] = {}
    global_values: dict[str, str] = {}
    group: dict[str, str] = {}
    regions: list[dict[str, str]] = []
    current: dict[str, str] | None = None
    pending_opcode: str | None = None
    pending_start = 0

    def finish_opcode(end: int) -> None:
        nonlocal pending_opcode
        if pending_opcode is None or current is None:
            return
        value = text[pending_start:end].strip()
        if not value:
            raise SfzError(f"opcode {pending_opcode}= has no value")
        current[pending_opcode] = value
        pending_opcode = None

    for marker in markers:
        finish_opcode(marker.start())
        header = marker.group("header")
        if header:
            header = header.lower()
            if header == "control":
                current = control
            elif header == "global":
                current = global_values
            elif header == "group":
                group = {}
                current = group
            elif header == "region":
                region = {**control, **global_values, **group}
                regions.append(region)
                current = region
        else:
            if current is None:
                raise SfzError(
                    f"opcode appears before a supported header: {marker.group(0)}"
                )
            pending_opcode = marker.group("opcode").lower()
            pending_start = marker.end()
    finish_opcode(len(text))
    if not regions:
        raise SfzError("SFZ contains no <region> entries")
    return regions


def integer_opcode(region: dict[str, str], name: str, default: int) -> int:
    try:
        return int(region.get(name, default))
    except ValueError as exc:
        raise SfzError(f"invalid integer for {name}: {region.get(name)!r}") from exc


def float_opcode(region: dict[str, str], name: str, default: float) -> float:
    try:
        return float(region.get(name, default))
    except ValueError as exc:
        raise SfzError(f"invalid number for {name}: {region.get(name)!r}") from exc


def unquote_path(value: str) -> str:
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def region_details(
    region: dict[str, str], sfz_path: Path, target_midi: int | None
) -> dict[str, Any]:
    key_value = midi_note(region["key"]) if "key" in region else None
    low_key = (
        midi_note(region["lokey"])
        if "lokey" in region
        else (key_value if key_value is not None else 0)
    )
    high_key = (
        midi_note(region["hikey"])
        if "hikey" in region
        else (key_value if key_value is not None else 127)
    )
    source_midi = (
        midi_note(region["pitch_keycenter"])
        if "pitch_keycenter" in region
        else (key_value if key_value is not None else 60)
    )
    low_velocity = integer_opcode(region, "lovel", 0)
    high_velocity = integer_opcode(region, "hivel", 127)
    if low_key > high_key:
        raise SfzError(f"invalid key range: {low_key}-{high_key}")
    if not 0 <= low_velocity <= high_velocity <= 127:
        raise SfzError(
            f"invalid velocity range: {low_velocity}-{high_velocity}"
        )
    sample_value = region.get("sample")
    if not sample_value:
        raise SfzError("region has no sample opcode")
    default_path = unquote_path(region.get("default_path", "")).replace("\\", "/")
    relative_sample = unquote_path(sample_value).replace("\\", "/")
    sample_path = (sfz_path.parent / default_path / relative_sample).resolve()
    shift = target_midi - source_midi if target_midi is not None else None
    low_random = float_opcode(region, "lorand", 0.0)
    high_random = float_opcode(region, "hirand", 1.0)
    if not 0.0 <= low_random <= high_random <= 1.0:
        raise SfzError(f"invalid random range: {low_random}-{high_random}")
    return {
        "target_note": note_name(target_midi) if target_midi is not None else None,
        "target_midi": target_midi,
        "key_range": [low_key, high_key],
        "key_range_names": [note_name(low_key), note_name(high_key)],
        "source_note": note_name(source_midi),
        "source_midi": source_midi,
        "semitone_shift": shift,
        "sonic_pi_rate": math.pow(2.0, shift / 12.0) if shift is not None else None,
        "velocity_range": [low_velocity, high_velocity],
        "random_range": [low_random, high_random],
        "sequence": {
            "length": integer_opcode(region, "seq_length", 1),
            "position": integer_opcode(region, "seq_position", 1),
        },
        "sample": sample_value,
        "sample_path": str(sample_path),
        "sample_exists": sample_path.is_file(),
    }


def inspect(
    sfz_path: Path, targets: list[int], velocity: int | None
) -> list[dict[str, Any]]:
    if velocity is not None and not 0 <= velocity <= 127:
        raise SfzError("velocity must be between 0 and 127")
    regions = parse_sfz(sfz_path)
    results: list[dict[str, Any]] = []
    requested_targets: list[int | None] = targets if targets else [None]
    for target in requested_targets:
        for region in regions:
            details = region_details(region, sfz_path, target)
            if (
                target is not None
                and not details["key_range"][0]
                <= target
                <= details["key_range"][1]
            ):
                continue
            if (
                velocity is not None
                and not details["velocity_range"][0]
                <= velocity
                <= details["velocity_range"][1]
            ):
                continue
            results.append(details)
    return results


def print_text(sfz_path: Path, results: list[dict[str, Any]]) -> None:
    print(f"SFZ: {sfz_path}")
    print(f"Matching regions: {len(results)}")
    for result in results:
        target = result["target_note"] or "inventory"
        shift = result["semitone_shift"]
        rate = result["sonic_pi_rate"]
        mapping = result["source_note"]
        if shift is not None and rate is not None:
            mapping += f" -> {target}, shift {shift:+d}, rate {rate:.8f}"
        velocity = result["velocity_range"]
        random_range = result["random_range"]
        status = "OK" if result["sample_exists"] else "MISSING"
        print(
            f"- {mapping}; velocity {velocity[0]}-{velocity[1]}; "
            f"random {random_range[0]:g}-{random_range[1]:g}; {status}"
        )
        print(f"  {result['sample_path']}")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Inspect SFZ regions and calculate Sonic Pi pitch rates."
    )
    parser.add_argument("sfz", type=Path)
    parser.add_argument(
        "--notes", nargs="+", default=[], help="target notes, such as A3 B3 D4"
    )
    parser.add_argument("--velocity", type=int, help="filter by MIDI velocity")
    parser.add_argument("--json", action="store_true", help="emit JSON output")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    sfz_path = args.sfz.expanduser().resolve()
    try:
        targets = [midi_note(note) for note in args.notes]
        results = inspect(sfz_path, targets, args.velocity)
    except SfzError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 2
    if args.json:
        print(json.dumps({"sfz": str(sfz_path), "regions": results}, indent=2))
    else:
        print_text(sfz_path, results)
    if any(not result["sample_exists"] for result in results):
        return 3
    if targets and not results:
        print("ERROR: no regions matched the requested notes and velocity", file=sys.stderr)
        return 4
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
