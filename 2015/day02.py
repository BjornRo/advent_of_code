with open("in/d2.txt") as f:
    t = r = 0
    for a, b, c in (map(int, x.split("x")) for x in f):
        ab, bc, ac = a * b, b * c, a * c
        t += (2 * ab) + (2 * bc) + (2 * ac) + min(ab, bc, ac)
        r += sum(sorted((a << 1, b << 1, c << 1))[:2]) + ab * c
    print("Part 1:", t)
    print("Part 2:", r)
