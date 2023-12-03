# Part 1
def help(i: int, s: str) -> list:
    row = []
    digits = []
    index = i * 1000 - 1
    for j in f".{s}.":
        if j.isdigit():
            digits.append(j)
            continue
        elif digits and not j.isdigit():
            index += 1
            dig = (index,int("".join(digits)))
            for _ in range(len(digits)):
                row.append(dig)
            digits.clear()
        row.append(j)
    return row

with open("d3.txt", "rt") as f:
    print(sum(dict((c for q in (j[1][l-1:l+2] for j in (m[i-1:i+2] for m in [[help(p, k) for p,k in enumerate("".join(z) for z in zip(*(["."] + x + ["."] for x in map(list,zip(*"".join(map(lambda x: x if x.isdigit() or x in (".","\n") else "*",f.read())).strip().split("\n"))))))]] for i in range(1,len(m)-1)) for l in range(1,len(j[0])-2) if (j[0][l] == "*" or j[1][l] == "*" or j[2][l] == "*")) for c in q if not isinstance(c, str))).values()))
