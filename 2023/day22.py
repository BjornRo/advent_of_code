import re
from collections import defaultdict
from itertools import batched

with open("in/e22.txt") as f:
    fa = re.compile(r"(\d+),(\d+),(\d+)~(\d+),(\d+),(\d+)")
    bricks = tuple(tuple(batched((int(d) for d in fa.match(x).groups()), 3)) for x in f)  # type:ignore


"""
Y ARE ROWS
X ARE COLS
-- ZERO INDEXING --
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
            if _b_height := brick[y][x]:
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
    # for cz, b in settled_stack:
    #     print(cz)
    #     for e in b:
    #         print(e)
    # print()
    # for b in cum_height:
    #     print(b)
    # breakpoint()

index_to_overlap: defaultdict[int, set[int]] = defaultdict(set)
ci = 0
for ci, (cz1, b_height1, b1) in enumerate(settled_stack):
    cz1 += b_height1
    # Find next overlapping pieces to current pieces
    for ci2, (cz2, b_height2, b2) in enumerate(settled_stack[ci+1:], ci+1):
        if cz1 == cz2:
            if overlaps_xy(b1, b2):
                index_to_overlap[ci].add(ci2)
        elif cz1 < cz2:
            break
    print(index_to_overlap)
index_to_overlap[ci] = set()


for cz, bh, b in reversed(settled_stack):
    print(cz, bh)
    for e in b:
        print(e)

# for b in cum_height:
#     print(b)


RemovedBricks = int
BrickIndex = int
SupportsBricks = tuple[BrickIndex, ...]
State = tuple[BrickIndex, SupportsBricks]


def benga(tower: list[tuple[int, int, list[list[int]]]], overlap_mapping: defaultdict[int, set[int]]):
    ci = 0
    for ci, (cz1, b_height1, b1) in enumerate(tower):
        # find pieces on current index
        overlaps = len(overlap_mapping[ci])
        for ci2, (cz2, b_height2, b2) in enumerate(tower[ci+1:], ci+1):
            if cz1 != cz2:
                break
            if overlap_mapping[ci]:
                pass


benga(settled_stack, index_to_overlap)
