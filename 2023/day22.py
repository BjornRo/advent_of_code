import re

with open("in/d22.txt") as f:
    fa = re.compile(r"(\d+),(\d+),(\d+)~(\d+),(\d+),(\d+)")
    bricks = tuple((x[:3], x[3:]) for x in (tuple(int(d) for d in fa.match(x).groups()) for x in f))  # type:ignore

MAX_GRID, MAX_HEIGHT = [(max(*x, *y) + 1, max(z) + 1) for x, y, z in [list(zip(*(w for b in bricks for w in b)))]][0]
ZPos, Id, BrickHeight = int, int, int
Brick = tuple[ZPos, BrickHeight, Id, list[list[int]]]


def line_to_2d(line: tuple[tuple[int, ...], ...], id: int) -> Brick:
    brick = [[0] * MAX_GRID for _ in range(MAX_GRID)]
    (x1, y1, z1), (x2, y2, z2) = line
    brick_height = z2 - z1 + 1
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            brick[y][x] = brick_height
    return (z1 - 1, brick_height, id, brick)


def lowest_z(cum_height: list[list[int]], brick: list[list[int]]) -> int:
    z = 0
    for y in range(MAX_GRID):
        for x in range(MAX_GRID):
            if brick[y][x] and (_c_height := cum_height[y][x]):
                z = max(_c_height, z)
    return z


def settle(bricks: tuple[Brick, ...] | list[Brick]) -> list[Brick]:
    cum_height, settled_stack = [[0] * MAX_GRID for _ in range(MAX_GRID)], []
    for _, b_height, id, brick in bricks:
        cum_z = lowest_z(cum_height, brick)
        for y in range(MAX_GRID):
            for x in range(MAX_GRID):
                if brick[y][x]:
                    cum_height[y][x] = cum_z + b_height
        settled_stack.append((cum_z, b_height, id, brick))
    return settled_stack


def check_deleted(bricks: tuple[Brick, ...] | list[Brick], pseudo_pop_id: int, count: bool) -> int:
    cum_height, total = [[0] * MAX_GRID for _ in range(MAX_GRID)], 0
    for zpos, b_height, id, brick in bricks:
        if id != pseudo_pop_id:
            cum_z = lowest_z(cum_height, brick)
            if zpos != cum_z:
                if not count:
                    return 1
                total += 1
            for y in range(MAX_GRID):
                for x in range(MAX_GRID):
                    if brick[y][x]:
                        cum_height[y][x] = cum_z + b_height
    return total


settled_stack = settle(tuple(sorted(line_to_2d(b, id) for id, b in enumerate(bricks))))

print("Part 1:", sum(not check_deleted(settled_stack, i, False) for i in range(len(bricks))))
print("Part 2:", sum(check_deleted(settled_stack, i, True) for i in range(len(bricks))))
