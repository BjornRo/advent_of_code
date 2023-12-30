import re

with open("in/d16.txt") as f:
    aunts = {
        i: dict(map(lambda x: (x[0], int(x[1])), re.findall(r"(\w+): (\d+)", row.strip().split(": ", 1)[1])))
        for i, row in enumerate(f, 1)
    }

ticker = """
children: 3
cats: 7
samoyeds: 2
pomeranians: 3
akitas: 0
vizslas: 0
goldfish: 5
trees: 3
cars: 2
perfumes: 1
""".strip()
ticker = tuple(map(lambda x: (x[0], int(x[1])), (x.split(": ") for x in ticker.split("\n"))))


for aunt, vals in aunts.items():
    ticks = 0
    for k, v in ticker:
        if k in vals and v == vals[k]:
            ticks += 1
    if ticks == 3:
        print("Part 1:", aunt)
        break


for aunt, vals in aunts.items():
    ticks = 0
    for k, v in ticker:
        if k in vals:
            if k in {"cats", "trees"}:
                if v < vals[k]:
                    ticks += 1
            elif k in {"pomeranians", "goldfish"}:
                if v > vals[k]:
                    ticks += 1
            elif v == vals[k]:
                ticks += 1
    if ticks == 3:
        print("Part 2:", aunt)
        break
