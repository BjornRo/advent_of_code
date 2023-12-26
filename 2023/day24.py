Vec3 = list[int] | tuple[int, ...] | tuple[int, int, int]
with open("in/d24.txt") as f:
    _g = (map(int, x.replace("@", ",").split(",")) for x in f)
    ishall: list[tuple[Vec3, Vec3]] = list(([x, y, z], [dx, dy, dz]) for x, y, z, dx, dy, dz in _g)


def part1(isbollar: list[tuple[Vec3, Vec3]], test_min: int, test_max: int, v=0) -> int:
    def crosses(a: tuple[Vec3, Vec3], b: tuple[Vec3, Vec3]) -> None | tuple[float, float]:
        ((pa1, pa2, _), (da1, da2, _)), ((pb1, pb2, _), (db1, db2, _)) = a, b
        if det := da2 * db1 - da1 * db2:  # Linear dependent vectors equals zero.
            dx, dy = pb1 - pa1, pb2 - pa2
            if (u := (dy * db1 - dx * db2) / det) >= 0 and (dy * da1 - dx * da2) / det >= 0:
                return (pa1 + da1 * u, pa2 + da2 * u)

    for i, a in enumerate(isbollar):
        for b in isbollar[i + 1 :]:
            if (p := crosses(a, b)) and test_min <= p[0] <= test_max and test_min <= p[1] <= test_max:
                v += 1
    return v


print("Part 1:", part1(ishall, 200_000_000_000_000, 400_000_000_000_000))
""" Part 2 """


def determinant3(mat: list[Vec3] | tuple[Vec3, ...] | tuple[Vec3, Vec3, Vec3]) -> int:
    (a, b, c), (d, e, f), (g, h, i) = mat  # Rule of Sarrus. Paranthesis below for readability
    return (a * e * i) + (b * f * g) + (c * d * h) - (c * e * g) - (b * d * i) - (a * f * h)


def cross_vec3(a: Vec3, b: Vec3) -> Vec3:
    (a1, a2, a3), (b1, b2, b3) = a, b
    return a2 * b3 - a3 * b2, a3 * b1 - a1 * b3, a1 * b2 - a2 * b1


# import numpy as np

a = [1, 3, 4]
b = [2, 7, -5]
cross_vec3(a, b)


mat3: list[tuple[Vec3, Vec3]] = []
for posdir in ishall:  # Find 3 independent vectors, super naive
    if len(mat3) == 3:
        if determinant3(list(zip(*mat3))[1]) != 0:
            break
        mat3.clear()
    mat3.append(posdir)
mat3 = [ishall[0], ishall[1], ishall[3]]
Mp, Md = list(zip(*mat3))
