import math
from decimal import Decimal

with open("in/e24.txt") as f:
    _g = (map(int, x.replace("@", ",").split(",")) for x in f)
    ishall: tuple["Isboll", ...] = tuple(((x, y, z), (dx, dy, dz)) for x, y, z, dx, dy, dz in _g)

Xyz, Delta = tuple[int, int, int], tuple[int, int, int]
Isboll = tuple[Xyz, Delta]


TEST_MIN_XY = 200_000_000_000_000
TEST_MAX_XY = 400_000_000_000_000

a = ishall[0]
b = ishall[3]

a = ishall[0]
b = ishall[1]


def cross_position(a: Isboll, b: Isboll, ignore_z=True) -> tuple[float, ...]:
    pos_a1, da = (a[0][:2], a[1][:2]) if ignore_z else a
    pos_b1, db = (b[0][:2], b[1][:2]) if ignore_z else b
    pos_a2 = tuple(posi + deltai for posi, deltai in zip(pos_a1, da))
    pos_b2 = tuple(posi + deltai for posi, deltai in zip(pos_b1, db))

    # x_prod = lambda u, v: tuple(u[(1 + i) % 3] * v[(2 + i) % 3] - u[(2 + i) % 3] * v[(1 + i) % 3] for i in range(3))
    if ignore_z:  # Sarrus rule
        sq = lambda x: Decimal(x) ** 2
        x_prod = lambda u, v: (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        stack = (pos_a1, pos_a2, pos_b1, pos_b2)
        homo = tuple((*x, 1) for x in stack)
        l1 = x_prod(homo[0], homo[1])
        l2 = x_prod(homo[2], homo[3])
        x, y, z = x_prod(l1, l2)
        return x / z, y / z
    return (-0.0, 0.0)


def intersects(a: Isboll, b: Isboll, ignore_z=True) -> bool:
    pos_a, da = (a[0][:2], a[1][:2]) if ignore_z else a
    pos_b, db = (b[0][:2], b[1][:2]) if ignore_z else b

    if ignore_z:
        det = da[0] * db[1] - da[1] * db[0]
        dx = pos_b[0] - pos_a[0]
        dy = pos_b[1] - pos_a[1]
        u = (dy * db[0] - dx * db[1]) / det
        v = (dy * da[0] - dx * da[1]) / det
        u,v

        return u > 0 and v > 0
    return True


def is_parallel(a: Isboll, b: Isboll, ignore_z=True, precision=14) -> bool:
    sq = lambda x: Decimal(x) ** 2
    da, db = (a[1][:2], b[1][:2]) if ignore_z else (a[1], b[1])
    dot = Decimal(sum(dai * dbi for dai, dbi in zip(da, db)))
    len_a = Decimal(sum(map(sq, da))).sqrt()
    len_b = Decimal(sum(map(sq, db))).sqrt()
    return round(abs(dot / (len_a * len_b)), precision) == 1.0


def part1(isbollar: tuple[Isboll, ...], test_min_xy: int, test_max_xy: int) -> int:
    total = 0
    for i, a in enumerate(isbollar):
        for b in isbollar[i + 1 :]:
            if not is_parallel(a, b):
                x, y = cross_position(a, b)
                if test_min_xy <= x <= test_max_xy and test_min_xy <= y <= test_max_xy:
                    print(a, b)
                    print(x, y)
                    total += 1
    return total


cross_position(ishall[0], ishall[2])

# part1(ishall, 7, 27)
