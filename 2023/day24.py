import math

with open("in/d24.txt") as f:
    _g = (map(int, x.replace("@", ",").split(",")) for x in f)
    ishall: tuple["Isboll", ...] = tuple(((x, y, z), (dx, dy, dz)) for x, y, z, dx, dy, dz in _g)

Xyz, Delta = tuple[int, int, int], tuple[int, int, int]
Isboll = tuple[Xyz, Delta]

TEST_MIN_XY = 200_000_000_000_000
TEST_MAX_XY = 400_000_000_000_000

cross_prod_vec3 = lambda u, v: (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
dot_prod = lambda u, v: sum(ui * vi for ui, vi in zip(u, v))
vec_len = lambda u: math.sqrt(sum(map(lambda x: x * x, u)))


# def is_parallel(a: Isboll, b: Isboll, ignore_z=True, precision=10) -> bool:
#     da, db = (a[1][:2], b[1][:2]) if ignore_z else (a[1], b[1])
#     dot = dot_prod(da, db)
#     len_a = vec_len(da)
#     len_b = vec_len(db)
#     return round(abs(dot / (len_a * len_b)), precision) == 1.0


def cross_position(a: Isboll, b: Isboll, ignore_z=True) -> tuple[float, ...]:
    pos_a1, da = (a[0][:2], a[1][:2]) if ignore_z else a
    pos_b1, db = (b[0][:2], b[1][:2]) if ignore_z else b
    pos_a2 = tuple(posi + deltai for posi, deltai in zip(pos_a1, da))
    pos_b2 = tuple(posi + deltai for posi, deltai in zip(pos_b1, db))

    if ignore_z:
        stack = (pos_a1, pos_a2, pos_b1, pos_b2)
        homo = tuple((*x, 1) for x in stack)
        l1 = cross_prod_vec3(homo[0], homo[1])
        l2 = cross_prod_vec3(homo[2], homo[3])
        x, y, z = cross_prod_vec3(l1, l2)
        return x / z, y / z
    return (-0.0, 0.0)


def intersects(a: Isboll, b: Isboll, ignore_z=True) -> bool:
    pos_a, da = (a[0][:2], a[1][:2]) if ignore_z else a
    pos_b, db = (b[0][:2], b[1][:2]) if ignore_z else b

    if ignore_z:
        det = db[0] * da[1] - db[1] * da[0]
        if det != 0:
            dx = pos_b[0] - pos_a[0]
            dy = pos_b[1] - pos_a[1]
            u = (dy * db[0] - dx * db[1]) / det
            v = (dy * da[0] - dx * da[1]) / det
            return u >= 0 and v >= 0
    return False


def part1(isbollar: tuple[Isboll, ...], test_min_xy: int, test_max_xy: int, total=0) -> int:
    for i, a in enumerate(isbollar):
        for b in isbollar[i + 1 :]:
            if intersects(a, b):
                x, y = cross_position(a, b)
                if test_min_xy <= x <= test_max_xy and test_min_xy <= y <= test_max_xy:
                    total += 1
    return total


# print(part1(ishall, 7, 27))
print(part1(ishall, TEST_MIN_XY, TEST_MAX_XY))
