from dataclasses import dataclass
from itertools import permutations

with open("in/d22.txt") as f:
    f.readline()
    f.readline()
    fs = [x.rstrip().rsplit("/", 1)[1].replace("node-x", "").replace("-y", " ").split() for x in f]

noodle = lambda row, col, size, use, avail, *_: (int(row), int(col), int(size[:-1]), int(use[:-1]), int(avail[:-1]))
viability = lambda node_a, node_b: (used := noodle(*node_a)[-2]) and (used <= noodle(*node_b)[-1])


@dataclass
class Block:
    size: int
    used: int


def swap_block(a: Block, b: Block) -> bool:
    if a.used <= b.size and b.used <= a.size:
        a.used, b.used = b.used, a.used
        return True
    return False


def move_up(curr_pos: tuple[int, int], steps=0):
    while (npos := move_up_one(*curr_pos)) != curr_pos:
        steps += 1
        curr_pos = npos
    return steps, curr_pos


def move_up_one(row: int, col: int):
    return (r, col) if (r := row - 1) >= 0 and swap_block(grid[row][col], grid[r][col]) else (row, col)


def move_down_one(row: int, col: int):
    return (r, col) if (r := row + 1) > MAX_ROW and swap_block(grid[row][col], grid[r][col]) else (row, col)


def move_left_one(row: int, col: int):
    return (row, c) if (c := col - 1) >= 0 and swap_block(grid[row][col], grid[row][c]) else (row, col)


def move_right_one(row: int, col: int):
    return (row, c) if (c := col + 1) < MAX_COL and swap_block(grid[row][col], grid[row][c]) else (row, col)


MAX_COL, MAX_ROW = map(lambda x: int(x) + 1, fs[-1][:2])
grid: list[list[Block]] = [[Block(0, 0)] * MAX_COL for _ in range(MAX_ROW)]
empty = (-1, -1)
for col, row, size, used, _ in map(lambda x: noodle(*x), fs):
    grid[row][col] = Block(size, used)
    if not used:
        empty = (row, col)

steps = 0
while empty != (0, 1):
    steps, empty = move_up(empty)
    while empty != (0, 1):
        empty = move_left_one(*empty)
        steps += 1
        nsteps, empty = move_up(empty)
        steps += nsteps
        if nsteps:  # Test if we can move upwards
            while empty != (nempty := move_right_one(*empty)):
                empty = nempty
                steps += 1
            while empty != (0, 1):
                empty = move_right_one(*move_up_one(*move_left_one(*move_left_one(*move_down_one(*empty)))))
                steps += 5
print("Part 1:", sum(viability(a, b) for a, b in permutations(fs, 2)))
print("Part 2:", steps)
