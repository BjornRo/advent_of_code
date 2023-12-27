def help(i: int, s: str, digits = []) -> list:
    row = []
    index = i * 1000 - 1
    for j in s:
        if j.isdigit():
            digits.append(j)
            continue
        elif digits and not j.isdigit():
            index += 1
            row += [(index, int("".join(digits))) for _ in range(len(digits))]
            digits.clear()
        row.append(j)
    return row

# Part 1
with open("d3.txt", "rt") as f:
    print("Part 1:", sum(dict((c for q in (j[1][l-1:l+2] for j in (m[i-1:i+2] for m in [[help(p, k) for p,k in enumerate(map(lambda x: f".{x}.",("".join(z) for z in zip(*(["."] + x + ["."] for x in map(list,zip(*"".join(map(lambda x: x if x.isdigit() or x in (".","\n") else "*",f.read())).strip().split("\n"))))))))]] for i in range(1,len(m)-1)) for l in range(1,len(j[0])-2) if (j[0][l] == "*" or j[1][l] == "*" or j[2][l] == "*")) for c in q if not isinstance(c, str))).values()))

# Part 2
with open("d3.txt", "rt") as f:
    print("Part 2:", sum(list(e.values())[0]*list(e.values())[1] for e in (dict(list(filter(lambda t: isinstance(t, tuple), j[0][l-1:l+2])) + list(filter(lambda t: isinstance(t, tuple), j[1][l-1:l+2])) + list(filter(lambda t: isinstance(t, tuple), j[2][l-1:l+2]))) for j in (m[i-1:i+2] for m in [[help(p, k) for p,k in enumerate(map(lambda x: f".{x}.",("".join(z) for z in zip(*(["."] + x + ["."] for x in map(list,zip(*"".join(map(lambda x: x if x.isdigit() or x in (".","\n") else "*",f.read())).strip().split("\n"))))))))]] for i in range(1,len(m)-1)) for l in range(1,len(j[0])-2) if j[1][l] == "*") if len(e) == 2))
