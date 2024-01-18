from dataclasses import dataclass

with open("in/d22.txt") as f:
    f.readline()
    f.readline()
    fs = [x.rstrip().rsplit("/", 1)[1].replace("node-x", "").replace("-y", " ").split() for x in f]

noodle = lambda row, col, size, use, avail, *_: (int(row), int(col), int(size[:-1]), int(use[:-1]), int(avail[:-1]))


@dataclass
class Block:
    size: int
    used: int


def swap_block(a: Block, b: Block) -> bool:
    if a.used <= b.size and b.used <= a.size:
        a.used, b.used = b.used, a.used
        return True
    return False


mv_up_one = lambda r, c: (y, c) if (y := r - 1) >= 0 and swap_block(grid[row][c], grid[y][c]) else (r, c)
mv_down_one = lambda r, c: (y, c) if (y := r + 1) > MAX_ROW and swap_block(grid[r][c], grid[y][c]) else (r, c)
mv_left_one = lambda r, c: (r, x) if (x := c - 1) >= 0 and swap_block(grid[r][c], grid[r][x]) else (r, c)
mv_right_one = lambda r, c: (r, x) if (x := c + 1) < MAX_COL and swap_block(grid[r][c], grid[r][x]) else (r, c)
mv_up = lambda c_pos, steps=0: (steps, c_pos) if (npos := mv_up_one(*c_pos)) == c_pos else mv_up(npos, steps + 1)

MAX_COL, MAX_ROW = map(lambda x: int(x) + 1, fs[-1][:2])
grid: list[list[Block]] = [[Block(0, 0)] * MAX_COL for _ in range(MAX_ROW)]
empty = (-1, -1)
for col, row, size, used, _ in map(lambda x: noodle(*x), fs):
    grid[row][col] = Block(size, used)
    if not used:
        empty = (row, col)

steps, empty = mv_up(empty)
while empty != (0, 1):
    empty = mv_left_one(*empty)
    steps += 1
    nsteps, empty = mv_up(empty)
    steps += nsteps
    if nsteps:  # Test if we can move upwards
        while empty != (nempty := mv_right_one(*empty)):
            empty = nempty
            steps += 1
        while empty != (0, 1):
            empty = mv_right_one(*mv_up_one(*mv_left_one(*mv_left_one(*mv_down_one(*empty)))))
            steps += 5

print("Part 1:", sum(used <= noodle(*b)[-1] for a in fs if (used := noodle(*a)[-2]) for b in fs if a != b))
print("Part 2:", steps)
