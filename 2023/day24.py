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

import z3

solver = z3.Solver()
a, b, c, d1, d2, d3 = map(z3.Int, ("a", "b", "c", "d1", "d2", "d3"))
for i, ((pa, pb, pc), (da, db, dc)) in enumerate(ishall):
    t = z3.Int(f"{i}")
    solver.add(a + d1 * t == pa + da * t)
    solver.add(b + d2 * t == pb + db * t)
    solver.add(c + d3 * t == pc + dc * t)
solver.check()
p0, p1, p2, da, db, dc = [solver.model().eval(x).as_long() for x in (a, b, c, d1, d2, d3)]  # type:ignore
print("Part 2:", p0 + p1 + p2)
