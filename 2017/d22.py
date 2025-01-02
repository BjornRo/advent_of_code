from enum import StrEnum
from typing import Callable


class Flag(StrEnum):
    CLEAN = "."
    WEAKENED = "W"
    INFECTED = "#"
    FLAGGED = "F"


def printFlag(matrix: dict[tuple[int, int], Flag]):
    dim = len(raw_matrix) * 5
    offset = (dim) // 2 - 1
    mat = [["."] * (dim - 1) for _ in range(dim - 1)]
    for i, f in matrix.items():
        r, c = i
        mat[r + offset][c + offset] = str(f)
    for i in mat:
        print("".join(i))
    print()


with open("in/d22.txt") as f:
    raw_matrix = tuple(x.rstrip() for x in f)

matrix = {(i, j): Flag.INFECTED for i, r in enumerate(raw_matrix) for j, c in enumerate(r) if c == "#"}
mid = len(raw_matrix) // 2
c2t = lambda c: (int(c.real), int(c.imag))


def contagious(
    matrix: dict[tuple[int, int], Flag],
    flag_func: Callable[[dict[tuple[int, int], Flag], complex, Flag], complex],
    burst_flag: Flag,
    max_activity: int,
) -> int:
    mat = matrix.copy()
    direction = complex(-1, 0)
    position = complex(mid, mid)

    get_flag = lambda c: mat.get(c2t(c), Flag.CLEAN)

    activity = 0
    burst = 0
    while True:
        start_tile = get_flag(position)
        while True:
            curr_tile = get_flag(position)
            if curr_tile != start_tile:
                break
            if curr_tile == burst_flag:
                burst += 1
            activity += 1
            if activity == max_activity:
                return burst
            direction *= flag_func(mat, position, curr_tile)
            position += direction


def set_flag_p1(mat: dict[tuple[int, int], Flag], pos: complex, x: Flag) -> complex:
    if x == Flag.CLEAN:
        mat[c2t(pos)] = Flag.INFECTED
        return complex(0, 1)
    del mat[c2t(pos)]
    return complex(0, -1)


def set_flag_p2(mat: dict[tuple[int, int], Flag], pos: complex, x: Flag) -> complex:
    match x:
        case Flag.CLEAN:
            mat[c2t(pos)] = Flag.WEAKENED
            return complex(0, 1)
        case Flag.WEAKENED:
            mat[c2t(pos)] = Flag.INFECTED
            return complex(1, 0)  # identity
        case Flag.INFECTED:
            mat[c2t(pos)] = Flag.FLAGGED
            return complex(0, -1)
        case Flag.FLAGGED:
            del mat[c2t(pos)]
            return complex(-1, 0)


print(f"Part 1: {contagious(matrix, set_flag_p1, Flag.CLEAN, 10_000)}")
print(f"Part 2: {contagious(matrix, set_flag_p2, Flag.WEAKENED, 10_000_000)}")
