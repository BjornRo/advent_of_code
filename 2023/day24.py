with open("in/d24.txt") as f:
    _g = (map(int, x.replace("@", ",").split(",")) for x in f)
    ishall: list[tuple[list[int], list[int]]] = list(([x, y, z], [dx, dy, dz]) for x, y, z, dx, dy, dz in _g)


def part1(isbollar: list[tuple[list[int], list[int]]], test_min_xy: int, test_max_xy: int, total=0) -> int:
    def intersects(a: tuple[list[int], list[int]], b: tuple[list[int], list[int]]) -> bool:
        pos_a, da = a
        pos_b, db = b  # Linear dependent vectors equals zero.
        if (det := db[0] * da[1] - db[1] * da[0]) == 0:
            return False
        dx = pos_b[0] - pos_a[0]
        dy = pos_b[1] - pos_a[1]
        u = (dy * db[0] - dx * db[1]) / det
        v = (dy * da[0] - dx * da[1]) / det
        return u >= 0 and v >= 0

    def cross_position(a: tuple[list[int], list[int]], b: tuple[list[int], list[int]]) -> tuple[float, ...]:
        cross_prod_vec3 = lambda u, v: (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        pos_a1, da = a[0][:2], a[1][:2]
        pos_b1, db = b[0][:2], b[1][:2]
        pos_a2 = tuple(posi + deltai for posi, deltai in zip(pos_a1, da))
        pos_b2 = tuple(posi + deltai for posi, deltai in zip(pos_b1, db))
        stack = (pos_a1, pos_a2, pos_b1, pos_b2)
        homo = tuple((*x, 1) for x in stack)
        l1 = cross_prod_vec3(homo[0], homo[1])
        l2 = cross_prod_vec3(homo[2], homo[3])
        x, y, z = cross_prod_vec3(l1, l2)
        return x / z, y / z

    for i, a in enumerate(isbollar):
        for b in isbollar[i + 1 :]:
            if intersects(a[:2], b[:2]):
                x, y = cross_position(a, b)
                if test_min_xy <= x <= test_max_xy and test_min_xy <= y <= test_max_xy:
                    total += 1
    return total


TEST_MIN_XY, TEST_MAX_XY = 200_000_000_000_000, 400_000_000_000_000
print("Part 1:", part1(ishall, TEST_MIN_XY, TEST_MAX_XY))

""" Part 2 """


def intersect(pos_a: list[int], da: list[int], pos_b: list[int], db: list[int]) -> bool:
    if (det := db[0] * da[1] - db[1] * da[0]) == 0:
        return False
    dx = pos_b[0] - pos_a[0]
    dy = pos_b[1] - pos_a[1]
    u = dy * db[0] - dx * db[1] / det
    v = dy * da[0] - dx * da[1] / det
    return u >= 0 and v >= 0


# add_vec = lambda u, v: tuple(ui + vi for ui, vi in zip(u, v))
sub_vec = lambda u, v: [vi - ui for vi, ui in zip(v, u)]


def add_vec2(u: list[int], v: list[int]):
    for i in range(2):
        u[i] += v[i]


# sorted(((x, sum(map(abs, x[1]))) for x in ishall), key=lambda i: i[1])
# isrink = tuple(
#     Line(a[:2], b[:2]) for (a, b), _ in sorted(((x, sum(map(abs, x[1]))) for x in ishall), key=lambda i: i[1])
# )
isrink = [(a[:2], b[:2]) for (a, b), _ in sorted(((x, sum(map(abs, x[1]))) for x in ishall), key=lambda i: i[1])]

line_a = isrink[0]
line_b = isrink[1]
line_c = isrink[2]
line_d = isrink[3]
line_e = isrink[4]
pos_a, da = isrink[0]
pos_b, db = isrink[1]
pos_c, dc = isrink[2]
pos_d, dd = isrink[3]
pos_e, de = isrink[4]
point_a = pos_a.copy()
s = 160_000
print(s)
for i in range(s, s * 2):
    add_vec2(point_a, da)
    point_b = pos_b.copy()
    for j in range(100000):
        add_vec2(point_b, db)
        dir_ab = sub_vec(point_a, point_b)
        dir_ba = sub_vec(point_b, point_a)
        if all(intersect(point_a, dir_ab, *x) or intersect(point_a, dir_ba, *x) for x in isrink[2:]):
            print(i, j, (point_a, dir_ab))
            pass
