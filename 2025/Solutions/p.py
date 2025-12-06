from functools import reduce
from itertools import batched
from operator import add, mul

with open("in/d06t.txt") as f:
    d = f.read().strip()

n, ops = d.strip().rsplit("\n", 1)
op = ops.replace(" ", "")

total = 0
for o, v in zip(op, [[int(y) for y in x if y.strip()] for x in batched(map("".join, (zip(*n.split("\n")))), len(op))]):
    total += reduce(add, v, 0) if o == "+" else reduce(mul, v, 1)
