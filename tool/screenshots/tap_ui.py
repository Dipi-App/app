#!/usr/bin/env python3
"""Find a UI node on the emulator and print the tap point (cx cy)."""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as Et


def parse_bounds(raw: str) -> tuple[int, int, int, int] | None:
    match = re.fullmatch(r"\[(\d+),(\d+)\]\[(\d+),(\d+)\]", raw)
    if not match:
        return None
    x1, y1, x2, y2 = (int(value) for value in match.groups())
    return x1, y1, x2, y2


def node_text(node: Et.Element) -> str:
    return " ".join(
        part
        for part in (
            node.attrib.get("text", ""),
            node.attrib.get("content-desc", ""),
        )
        if part
    )


def walk(root: Et.Element) -> list[tuple[Et.Element, tuple[int, int, int, int]]]:
    found: list[tuple[Et.Element, tuple[int, int, int, int]]] = []
    for node in root.iter():
        bounds = parse_bounds(node.attrib.get("bounds", ""))
        if bounds is None:
            continue
        found.append((node, bounds))
    return found


def pick(
    nodes: list[tuple[Et.Element, tuple[int, int, int, int]]],
    needle: str,
    contains: bool,
    nth: int,
) -> tuple[int, int] | None:
    matches: list[tuple[int, int]] = []
    for node, (x1, y1, x2, y2) in nodes:
        hay = node_text(node)
        if contains:
            ok = needle in hay
        else:
            ok = hay == needle
        if not ok:
            continue
        if x2 <= x1 or y2 <= y1:
            continue
        matches.append(((x1 + x2) // 2, (y1 + y2) // 2))
    if nth < 0 or nth >= len(matches):
        return None
    return matches[nth]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("xml")
    parser.add_argument("needle")
    parser.add_argument("--contains", action="store_true")
    parser.add_argument("--nth", type=int, default=0)
    args = parser.parse_args()

    try:
        tree = Et.parse(args.xml)
    except Et.ParseError as error:
        print(f"parse error: {error}", file=sys.stderr)
        return 2

    point = pick(walk(tree.getroot()), args.needle, args.contains, args.nth)
    if point is None:
        return 1
    print(f"{point[0]} {point[1]}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
