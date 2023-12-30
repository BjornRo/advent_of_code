import itertools as it
import math
import re

with open("in/d15.txt") as f:
    chemicals = tuple(zip(*(map(int, re.findall(r"-?\d+", s)) for s in f)))

part1 = part2 = 0
for comb in (c for c in it.product(range(1, 102 - len(chemicals[0])), repeat=len(chemicals[0])) if sum(c) == 100):
    tmp = math.prod(max(0, sum(x * y for x, y in zip(comb, c))) for c in chemicals[:-1])
    part1 = max(tmp, part1)
    if sum(x * y for x, y in zip(comb, chemicals[-1])) == 500:
        part2 = max(tmp, part2)
print("Part 1:", part1)
print("Part 2:", part2)
