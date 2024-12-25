from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Literal, cast

with open("in/d21t.txt") as f:
    raw_data = f.read().strip().splitlines()

data = [(tuple(map(lambda x: int(x, 16), s)), int(s[:-1])) for s in raw_data]

type Directions = Literal["^", "A", "<", "v", ">", ""]
A = 10


@dataclass
class Point:
    row: int
    col: int

    def __add__(self, other: Point) -> Point:
        return Point(self.row + other.row, self.col + other.col)

    def __sub__(self, other: Point) -> Point:
        return Point(self.row - other.row, self.col - other.col)

    def horizontal(self) -> Directions:
        return cast(Directions, ("<" if self.col < 0 else "" if self.col == 0 else ">") * abs(self.col))

    def vertical(self) -> Directions:
        return cast(Directions, ("^" if self.row < 0 else "" if self.row == 0 else "v") * abs(self.row))

    def steps(self) -> Directions:
        if self.row > 0:
            return cast(Directions, self.vertical() + self.horizontal())
        else:
            return cast(Directions, self.horizontal() + self.vertical())

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

# for data(keypad starts at A):  robots(1, "<A")

pos = "A"
next_pos = pos
next_pos = "^"
next_pos = "v"
next_pos = "<"
next_pos = ">"


# too low 133093870844
def robots(level: int, string: str) -> tuple[str, int]:
    if (key := (level, string)) in memo:
        return "", memo[key]

    if level == 0:
        return string, len(string)

    pos: Directions = "A"
    strlen = 0
    final_str = ""

    for next_pos in cast(list[Directions], string):
        point = dirpad(next_pos) - dirpad(pos)
        if point.row > 0:
            next_steps = point.vertical() + point.horizontal()
        else:
            next_steps = point.horizontal() + point.vertical()
        new_str, steps = robots(level - 1, next_steps + "A")
        final_str += new_str
        strlen += steps
        pos = next_pos
    # memo[(level, string)] = strlen

    return final_str, strlen


# <vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A
# v<<A>>^A<A>AvA<^AA>A<vAAA>^A

for kp, num in data:
    new_kp = [A] + [x for x in kp]
    steps = ["".join([(keypad[b] - keypad[a]).steps() + "A" for a, b in zip(new_kp[:-1], new_kp[1:])])][0]

    memo.clear()
    s, val = robots(1, steps)
    print(s)
    print(val)
    break
