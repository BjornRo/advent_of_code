import re
import sys
from collections import defaultdict
from copy import deepcopy
from itertools import batched

sys.setrecursionlimit(4000)

with open("in/d22.txt") as f:
    fa = re.compile(r"(\d+),(\d+),(\d+)~(\d+),(\d+),(\d+)")
    bricks = tuple(tuple(batched((int(d) for d in fa.match(x).groups()), 3)) for x in f)  # type:ignore


"""
Y ARE ROWS
X ARE COLS
-- ZERO INDEXING --

1059 too high
1058 too high
"""

# 3 for test, 10 for real
MAX_GRID = max(e for i in list(zip(*(w for b in bricks for w in b)))[:2] for e in i) + 1
MAX_HEIGHT = max(list(zip(*(w for b in bricks for w in b)))[2]) + 1


def line_to_2d(line: tuple[tuple[int, ...], ...]) -> tuple[int, int, list[list[int]]]:
    brick = [[0] * MAX_GRID for _ in range(MAX_GRID)]
    (x1, y1, z1), (x2, y2, z2) = line
    brick_height = z2 - z1 + 1
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            brick[y][x] = brick_height
    # Returns lowest z position and shape in 3d. Value is block height
    return (z1 - 1, brick_height, brick)


def overlaps_xy(b1: list[list[int]], b2: list[list[int]]) -> bool:
    for i in range(MAX_GRID):
        for j in range(MAX_GRID):
            if b1[i][j] and b2[i][j]:
                return True
    return False


def lowest_z(cum_height: list[list[int]], brick: list[list[int]]) -> int:
    z = 0
    for y in range(MAX_GRID):
        for x in range(MAX_GRID):
            if brick[y][x]:
                if _c_height := cum_height[y][x]:
                    z = max(_c_height, z)
    return z


new_bricks = tuple(sorted(line_to_2d(b) for b in bricks))

cum_height: list[list[int]] = [[0] * MAX_GRID for _ in range(MAX_GRID)]
settled_stack: list[tuple[int, int, list[list[int]]]] = []
for z, b_height, brick in new_bricks:
    cum_z = lowest_z(cum_height, brick)
    for y in range(MAX_GRID):
        for x in range(MAX_GRID):
            if brick[y][x]:
                cum_height[y][x] = cum_z + b_height
    settled_stack.append((cum_z, b_height, brick))


brick_supports_next: dict[int, set[int]] = {}
ci = 0
for ci, (cz1, b_height1, b1) in enumerate(settled_stack):
    brick_supports_next[ci] = set()
    cz1 += b_height1
    # Find next overlapping pieces to current pieces
    for ci2, (cz2, b_height2, b2) in enumerate(settled_stack[ci + 1 :], ci + 1):
        if cz1 == cz2:
            if overlaps_xy(b1, b2):
                brick_supports_next[ci].add(ci2)
        elif cz1 < cz2:
            break

brick_supports_previous: defaultdict[int, set[int]] = defaultdict(set)
for idx, s in brick_supports_next.items():
    for i in s:
        brick_supports_previous[i].add(idx)
brick_next = brick_supports_next
brick_previous = dict(brick_supports_previous)
# for cz, bh, b in reversed(settled_stack):
#     print(cz, bh)
#     for e in b:
#         print(e)

# for b in cum_height:
#     print(b)


def benga(idx: int, removed: int, prev_supports: dict):
    if idx == len(settled_stack):
        return removed
    max_val = 0
    supports = brick_next[idx]
    if all(len(prev_supports[j]) >= 2 for j in supports) or not brick_next[idx]:
        _prev_supports = deepcopy(prev_supports)
        if idx in prev_supports:
            _prev_supports.pop(idx)
        max_val = max(benga(idx + 1, removed + 1, _prev_supports), max_val)
    else:
        max_val = max(benga(idx + 1, removed, prev_supports), max_val)
    return max_val


print(benga(0, 0, brick_previous))
