import numpy as np


def conv(x):
    return tuple(tuple(int(y == "#") for y in i) for i in x)


flip = lambda x: tuple(i[::-1] for i in x)
rotate = lambda x: flip(zip(*x))
rules: dict[bytes, np.ndarray] = {}
with open("in/d21.txt") as f:
    for x, y in (map(lambda x: x.split("/"), x.rstrip().split(" => ")) for x in f):
        res = np.array(conv(y))
        shape = conv(x)
        shapef = flip(shape)
        for _ in range(4):
            shape = rotate(shape)
            shapef = rotate(shapef)
            rules[np.array(shape).tobytes()] = res
            rules[np.array(shapef).tobytes()] = res


def art(shape: np.ndarray, depth: int) -> int:
    if depth == 0:
        return np.sum(shape)
    size = len(shape)
    bs = 2 if size % 2 == 0 else 3
    steps = size // bs
    bsn = bs + 1
    new_matrix = np.zeros((bsn * steps, bsn * steps), dtype=int)
    for row in range(steps):
        for col in range(steps):
            new_block = rules[shape[bs * row : bs * row + bs, bs * col : bs * col + bs].tobytes()]
            new_matrix[bsn * row : bsn * row + bsn, bsn * col : bsn * col + bsn] = new_block
    return art(new_matrix, depth - 1)


start = np.array(conv((".#.", "..#", "###")))
print(f"Part 1: {art(start, 5)}")
print(f"Part 2: {art(start, 18)}")
