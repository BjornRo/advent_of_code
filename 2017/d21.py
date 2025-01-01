from itertools import batched

with open("in/d21.txt") as f:
    rules = {a: b for a, b in (tuple(map(lambda x: tuple(x.split("/")), x.rstrip().split(" => "))) for x in f)}

start = (
    ".#.",
    "..#",
    "###",
)


flip = lambda x: tuple(i[::-1] for i in x)
rotate = lambda x: flip(map("".join, zip(*x)))


def split_pieces(shape: tuple[str, ...], block_size: int) -> tuple[tuple[str, ...], ...]:
    size = len(shape[0])
    submatrices = []
    for i in range(0, size, block_size):
        for j in range(0, size, block_size):
            submatrix = tuple(shape[i + di][j : j + block_size] for di in range(block_size) if i + di < size)
            submatrices.append(submatrix)
    return tuple(submatrices)


pp = (
    (
        "..#",  # 0,0 -> 0
        "#.#",  # 0,1 -> 1
        "..#",  # 0,2 -> 2
    ),
    (
        "#.#",  # 1,0 -> 0
        ".#.",  # 1,1 -> 1
        "#..",  # 1,2 -> 2
    ),
    (
        "..#",  # 2,0 -> 3
        "#.#",  # 2,1 -> 4
        "..#",  # 2,2 -> 5
    ),
    (
        "...",  # 3,0 -> 3
        "#..",  # 3,1 -> 4
        "..#",  # 3,2 -> 5
    ),
)

"..#" "#.#"
"#.#" ".#."
"..#" "#.."
"..#" "..."

("..##.#", "#.#.#.", "..##..", "..#...", "#.##..", "..#..#")


def rebuild_blocks(shapes: tuple[tuple[str, ...], ...]):
    shape_len = len(shapes[0])
    num_blocks = len(shapes)
    factor = int(len(shapes) ** 0.5)
    flatten = [y for x in shapes for y in x]

    all_blocks = []
    for i in range(0, int(shape_len * 2 * num_blocks**0.5 + 1), shape_len * 2):
        for j in range(shape_len):
            all_blocks.append("".join(flatten[i + j : i + j + num_blocks : shape_len]))
    return tuple(all_blocks)


def map_rule(shape: tuple[str, ...]) -> tuple[str, ...]:
    for _ in range(4):
        shape = rotate(shape)
        if shape in rules:
            return rules[shape]

    shape = flip(shape)
    for _ in range(4):
        shape = rotate(shape)
        if shape in rules:
            return rules[shape]
    raise Exception


4, 3

for i in tuple(map_rule(x) for x in split_pieces(rebuild_blocks(pp), 2)):
    print(i)
print()
for i in rebuild_blocks(tuple(map_rule(x) for x in split_pieces(rebuild_blocks(pp), 2))):
    print(i)


build_3x3_to_6x6(pp)

build_blocks_to_shape(pp, 3)

split_pieces(build_3x3_to_6x6(pp), 2)


def art(shape: tuple[str, ...], depth: int):
    if depth == 0:
        return shape

    size = len(shape)
    if size % 2 == 0:
        new_shape = rebuild_blocks(tuple(map_rule(x) for x in split_pieces(shape, 2)))
    else:
        new_shape = rebuild_blocks(tuple(map_rule(x) for x in split_pieces(shape, 3)))
    raise Exception


# sum(sum(y == "#" for y in x) for x in shape)

# 758 too high
# 51 not right
print(art(start, 6))

print(f"Part 1: {1}")
print(f"Part 2: {2}")
