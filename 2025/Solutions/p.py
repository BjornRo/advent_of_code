from functools import reduce
from itertools import groupby
from operator import add, mul

with open("in/d06.txt") as f:
    d = f.read().strip().split("\n")

total = 0
for o, v in zip(d[-1].replace(" ", ""), [[int(y) for y in x] for b,x in groupby(map(lambda x: "".join(x).strip(), (zip(*d[:-1]))), str.isdigit) if b]):
    total += reduce(add, v, 0) if o == "+" else reduce(mul, v, 1)
