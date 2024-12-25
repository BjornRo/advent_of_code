from __future__ import annotations

from collections import defaultdict, deque
from dataclasses import dataclass
from typing import Literal, cast

with open("in/d21.txt") as f:
    raw_data = f.read().strip().splitlines()

data = [(tuple(map(lambda x: int(x, 16), s)), int(s[:-1])) for s in raw_data]

type Directions = Literal["^", "A", "<", "v", ">", ""]
A = 10

n_robots = 2


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

    def horizontal(self) -> Directions:
        return cast(Directions, ("<" if self.col < 0 else "" if self.col == 0 else ">") * abs(self.col))

    def vertical(self) -> Directions:
        return cast(Directions, ("^" if self.row < 0 else "" if self.row == 0 else "v") * abs(self.row))

    def keypad(self, to: Point):
        direction = to - self
        if self.row == 3 and direction.col < 0:
            return cast(Directions, direction.vertical() + direction.horizontal())
        if self.col == 0 and direction.row > 0:
            return cast(Directions, direction.horizontal() + direction.vertical())
        if direction.col < 0:
            return cast(Directions, direction.horizontal() + direction.vertical())
        if direction.col > 0:
            return cast(Directions, direction.vertical() + direction.horizontal())
        return cast(Directions, direction.horizontal() + direction.vertical())

    def as_tuple(self) -> tuple[int, int]:
        return self.row, self.col

    def manhattan(self, other: Point) -> int:
        return abs(self.row - other.row) + abs(self.col - other.col)


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
k = lambda a, b: keypad[b] - keypad[a]

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
    # if (key := (level, string)) in memo:
    #     return "", memo[key]

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

    # if memo.get((level, string), 1 << 64) > strlen:
    #     memo[(level, string)] = strlen

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

value = 0
for kp, num in data:
    new_kp = [A] + [x for x in kp]
    steps = ["".join([(keypad[a]).keypad(keypad[b]) + "A" for a, b in zip(new_kp[:-1], new_kp[1:])])][0]

    memo.clear()
    s, val = robots(n_robots, steps)
    print(steps)
    print("".join(map(str, kp[:-1])))
    print(s)
    value += val * num
    print(val)
    print()
print(value)
