with open("in/d24.txt") as f:
    _g = (map(int, x.replace("@", ",").split(",")) for x in f)
    ishall: list[tuple[list[int], list[int]]] = list(([x, y, z], [dx, dy, dz]) for x, y, z, dx, dy, dz in _g)


def part1(isbollar: list[tuple[list[int], list[int]]], test_min: int, test_max: int) -> int:
    def intersects(a: tuple[list[int], list[int]], b: tuple[list[int], list[int]]) -> bool:
        (pos_a, da), (pos_b, db) = a, b  # Linear dependent vectors equals zero.
        if (det := da[1] * db[0] - da[0] * db[1]) == 0:
            return False
        dx, dy = pos_b[0] - pos_a[0], pos_b[1] - pos_a[1]
        return (dy * db[0] - dx * db[1]) / det >= 0 and (dy * da[0] - dx * da[1]) / det >= 0

    def cross_position(a: tuple[list[int], list[int]], b: tuple[list[int], list[int]]) -> tuple[float, ...]:
        cross_prod_vec3 = lambda u, v: (u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0])
        pos_a1, da, pos_b1, db = a[0][:2], a[1][:2], b[0][:2], b[1][:2]
        pos_a2, pos_b2 = tuple(pi + di for pi, di in zip(pos_a1, da)), tuple(pi + di for pi, di in zip(pos_b1, db))
        homo = tuple((*x, 1) for x in (pos_a1, pos_a2, pos_b1, pos_b2))
        x, y, z = cross_prod_vec3(cross_prod_vec3(homo[0], homo[1]), cross_prod_vec3(homo[2], homo[3]))
        return x / z, y / z

    return sum(
        test_min <= p[0] <= test_max and test_min <= p[1] <= test_max
        for i, a in enumerate(isbollar)
        for b in isbollar[i + 1 :]
        if intersects(a, b) and (p := cross_position(a, b))
    )


print("Part 1:", part1(ishall, 200_000_000_000_000, 400_000_000_000_000))

""" Part 2 """


def det_mat3(mat: list[list[int]] | tuple[tuple[int, ...], ...] | tuple[list[int], ...], v=0):
    for i in range(3):  # Rule of sarrus
        j, k = (i + 1) % 3, (i + 2) % 3
        v += mat[0][i] * mat[1][j] * mat[2][k] - mat[2][i] * mat[1][j] * mat[0][k]
    return v


mat3: list[tuple[list[int], list[int]]] = []
for posdir in ishall:  # Find 3 independent vectors, super naive
    if len(mat3) == 3:
        if det_mat3(list(zip(*mat3))[1]) != 0:
            break
        mat3.clear()
    mat3.append(posdir)


# Linear combination of all vectors. U1+du1*t == U2+du2*t ==...
# Nice to solve, forgot all but the most basic stuff from linalg.
