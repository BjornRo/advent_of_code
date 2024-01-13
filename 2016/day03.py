from itertools import batched

with open("in/d3.txt") as f:
    triangles = tuple(tuple(map(int, x.rstrip().split())) for x in f)

triangle_cruncher = lambda t: sum(sx[0] + sx[1] > sx[2] for x in t if (sx := sorted(x)))
print("Part 1:", triangle_cruncher(triangles))
print("Part 2:", triangle_cruncher(batched((e for row in zip(*triangles) for e in row), 3)))
