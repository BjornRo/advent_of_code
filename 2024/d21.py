from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Literal, cast

with open("in/d21.txt") as f:
    raw_data = f.read().strip().splitlines()

data = [(s, int(s[:-1])) for s in raw_data]

type Directions = Literal["^", "A", "<", "v", ">", ""]
A = 10

n_robots = 25


@dataclass
class Point:
    row: int
    col: int

    def __add__(self, other: Point) -> Point:
        return Point(self.row + other.row, self.col + other.col)

    def __sub__(self, other: Point) -> Point:
        return Point(self.row - other.row, self.col - other.col)

    def __eq__(self, other: Point) -> bool:
        return self.row == other.row and self.col == other.col

    def as_tuple(self) -> tuple[int, int]:
        return self.row, self.col

    def manhattan(self, other: Point) -> int:
        return abs(self.row - other.row) + abs(self.col - other.col)

    def direction(self) -> str:
        if self.col < 0:
            return "<"
        if self.col > 0:
            return ">"
        if self.row < 0:
            return "^"
        # if self.row > 0:
        return "v"


"""
d21.DirPad.LEFT
d21.DirPad.UP
d21.DirPad.UP
A
d21.DirPad.RIGHT
d21.DirPad.UP
d21.DirPad.DOWN
d21.DirPad.DOWN
A
d21.DirPad.DOWN
"""


# v<A>^Av<<A>^A>AvA^Av<A<A>>^AAvA<^A>Av<A<A>>^AvA<^A>A

keypadp = {
    "7": Point(0, 0),
    "8": Point(0, 1),
    "9": Point(0, 2),
    "4": Point(1, 0),
    "5": Point(1, 1),
    "6": Point(1, 2),
    "1": Point(2, 0),
    "2": Point(2, 1),
    "3": Point(2, 2),
    "0": Point(3, 1),
    "A": Point(3, 2),
}

# .{ 7, 8, 9 },
# .{ 4, 5, 6 },
# .{ 1, 2, 3 },
# .{ X, 0, A },


# print(k(A, 4))
# print(k(A, 1).steps())
# print(k(3, 7).steps())


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


# too low 133093870844, 153656148712678
# too high 390073922586586
#          512223765078440
# 242337182910752


def dirpad(key: str) -> str:
    match key:
        case "^":
            return "vA"
        case "A":
            return "^>"
        case "<":
            return "v"
        case "v":
            return "<^>"
        case ">":
            return "Av"
        case _:
            return ""


def directions(start: str, to: str) -> str:
    match start, to:
        case ["A", "^"] | ["v", "<"] | [">", "v"]:
            return "<"
        case ["v", "^"] | [">", "A"]:
            return "^"
        case ["A", ">"] | ["^", "v"]:
            return "v"
        case ["<", "v"] | ["v", ">"] | ["^", "A"]:
            return ">"
        case _:
            raise Exception(f"not here please: {start}, {to}")


def robots(level: int, string: str) -> tuple[str, int]:
    if (key := (level, string)) in memo:
        return "", memo[key]

    if level == 0:
        return string, len(string)

    pos = "A"
    strlen = 0
    final_str = ""

    for next_pos in string:

        best_string = ""
        min_len = 1 << 64
        # current pos, visited
        stack = [(pos, "", "")]

        while stack:
            p, vis, dirs = stack.pop()

            if p == next_pos:
                s, steps = robots(level - 1, dirs + "A")
                if steps < min_len:
                    best_string = s
                    min_len = steps
                continue

            if p in vis:
                continue

            for i in dirpad(p):
                stack.append((i, vis + p, dirs + directions(p, i)))

        final_str += best_string
        strlen += min_len
        pos = next_pos

    if memo.get((level, string), 1 << 64) > strlen:
        memo[(level, string)] = strlen

    return final_str, strlen


# <vA<AA>>^AvAA<^A>A<v<A>>^AvA^A<vA>^A<v<A>^A>AAvA^A<v<A>A>^AAAvA<^A>A
# v<<A>>^A<A>AvA<^AA>A<vAAA>^A

# <v<A>>^AA<vA<A>>^AAvAA<^A>A<vA>^A<A>A<vA>^A<A>A<v<A>A>^AAvA<^A>A
# v<A<AA>>^AAvA<^A>AAvA^Av<A>^A<A>Av<A>^A<A>Av<A<A>>^AAvA<^A>A

# v<<A>>^AvA^Av<<A>>^AAv<A<A>>^AAvAA<^A>Av<A>^AA<A>Av<A<A>>^AAAvA<^A>A
#
# v<<A >>^A vA ^A v<<A>>^AA v<A <A>>^AA vAA <^A >A v<A >^AA <A >A v<A <A >>^AAAvA<^A>A

# <v<A>>^AvA^A<vA<AA>>^AAvA<^A>AAvA^A<vA>^AA<A>A<v<A>A>^AAAvA<^A>A
# .{ 7, 8, 9 },
# .{ 4, 5, 6 },
# .{ 1, 2, 3 },
# .{ X, 0, A },


# 72, 964
# 70, 140
# 70, 413
# 68, 670
# 74, 593


# 70, 83
# 74, 935
# 72, 964
# 76, 149
# 66, 789
# Part 1: 207806


keypad = [
    "789",
    "456",
    "123",
    " 0A",
]


value = 0
for kp, num in data:
    memo.clear()
    new_kp = [x for x in kp]

    best_string = ""
    min_len = 1 << 64

    # start, vis, dirs, current_max_steps, to_visit
    stack = [(Point(3, 2), "", "", keypadp["A"].manhattan(keypadp[new_kp[0]]), new_kp)]
    while stack:
        pos, vis, dirs, max_steps, to_visit = stack.pop()

        row, col = pos.as_tuple()
        elem = keypad[row][col]
        if elem == to_visit[0]:
            if len(to_visit) == 1:
                s, val = robots(n_robots, dirs + "A")
                if val < min_len:
                    best_string = s
                    min_len = val
                continue
            stack.append((pos, "", dirs + "A", keypadp[to_visit[0]].manhattan(keypadp[to_visit[1]]), to_visit[1:]))
            continue
        if elem in vis or len(vis) >= max_steps:
            continue
        new_vis = vis + elem


        for p in Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1):
            new_pos = pos + p
            crow, ccol = new_pos.as_tuple()
            if 0 <= crow < len(keypad) and 0 <= ccol < len(keypad[0]):
                elem = keypad[crow][ccol]
                if elem != " ":
                    stack.append((new_pos, new_vis, dirs + p.direction(), max_steps, to_visit))

    print(best_string)
    value += min_len * num
    print(min_len)
    print()
print(value)