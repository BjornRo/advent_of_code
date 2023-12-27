with open("in/d22.txt") as f:
    bricks = tuple(tuple(map(int, x.replace("~", ",").split(","))) for x in f)
ZPos, ZBrick, Id, GRID = int, int, int, next(max(*a, *b, *d, *e) + 1 for a, b, _, d, e, _ in [tuple(zip(*(bricks)))])
Brick = tuple[ZPos, ZBrick, Id, list[list[int]]]


def line_to_2d(line: tuple[int, ...], id: int) -> Brick:
    (x1, y1, z1, x2, y2, z2), brick = line, [[0] * GRID for _ in range(GRID)]
    brick_height = z2 - z1 + 1
    for y in range(y1, y2 + 1):
        for x in range(x1, x2 + 1):
            brick[y][x] = brick_height
    return z1 - 1, brick_height, id, brick


def lowest_z(cum_height: list[list[int]], brick: list[list[int]], z=0) -> int:
    for y in range(GRID):
        for x in range(GRID):
            if brick[y][x] and (_c_height := cum_height[y][x]):
                z = max(_c_height, z)
    return z


def settle(bricks: tuple[Brick, ...] | list[Brick]) -> list[Brick]:
    cum_height, settled_stack = [[0] * GRID for _ in range(GRID)], []
    for _, b_height, id, brick in bricks:
        cum_z = lowest_z(cum_height, brick)
        for y in range(GRID):
            for x in range(GRID):
                if brick[y][x]:
                    cum_height[y][x] = cum_z + b_height
        settled_stack.append((cum_z, b_height, id, brick))
    return settled_stack


def check_deleted(bricks: tuple[Brick, ...] | list[Brick], pseudo_pop_id: int, count: bool) -> int:
    cum_height, total = [[0] * GRID for _ in range(GRID)], 0
    for zpos, b_height, id, brick in bricks:
        if id != pseudo_pop_id:
            cum_z = lowest_z(cum_height, brick)
            if zpos != cum_z:
                if not count:
                    return 0
                total += 1
            for y in range(GRID):
                for x in range(GRID):
                    if brick[y][x]:
                        cum_height[y][x] = cum_z + b_height
    return total if count else 1


settled_stack, b_len = settle(tuple(sorted(line_to_2d(b, id) for id, b in enumerate(bricks)))), len(bricks)
print("Part 1:", sum(check_deleted(settled_stack, i, False) for i in range(b_len)))
print("Part 2:", sum(check_deleted(settled_stack, i, True) for i in range(b_len)))
