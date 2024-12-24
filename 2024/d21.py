from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Literal

with open("in/d23t.txt") as f:
    data = f.read().strip().splitlines()

type Directions = Literal["^", "A", "<", "v", ">"]
A = 10


@dataclass
class Point:
    row: int
    col: int

    def add(self, other: Point) -> Point:
        return Point(self.row + other.row, self.col + other.col)

    def sub(self, other: Point) -> Point:
        return Point(self.row - other.row, self.col - other.col)

    def as_tuple(self) -> tuple[int, int]:
        return self.row, self.col

    def manhattan(self, other: Point) -> int:
        return abs(self.row - other.row) + abs(self.col - other.col)


def dirpad(key: Directions) -> Point:
    match key:
        case "^":
            return Point(0, 1)
        case "A":
            return Point(0, 2)
        case "<":
            return Point(1, 0)
        case "v":
            return Point(1, 1)
        case ">":
            return Point(1, 2)
        case _:
            raise Exception


keypad = {
    7: Point(0, 0),
    8: Point(0, 1),
    9: Point(0, 2),
    4: Point(1, 0),
    5: Point(1, 1),
    6: Point(1, 2),
    1: Point(2, 0),
    2: Point(2, 1),
    3: Point(2, 2),
    0: Point(3, 1),
    A: Point(3, 2),
}


kp_row = 3
kp_col = 2

dp_row = 0
dp_col = 2

memo = {}

# robots(1, "<A")


def robots(level: int, string: str) -> tuple[str, int]:
    if level == 0:
        return string, len(string)

    pos = "A"
    strlen = 0
    final_str = ""

    for next_pos in string:
        pass
        # res = robots(level, target_index, target, keypad_pos, dir, steps + 1)
    return final_str, strlen
