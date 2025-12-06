from itertools import groupby

with open("in/d06.txt") as f:
    d = f.read().strip().split("\n")

total = sum(eval(o.join(v)) for o,v in zip(d[-1].replace(" ", ""), [list(x) for b,x in groupby(map(lambda x: "".join(x).strip(), zip(*d[:-1])), str.isdigit) if b]))