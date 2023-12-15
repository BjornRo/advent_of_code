with open("d6.txt", "rt") as f:
    for j,p in enumerate(x if not j else [[int("".join(map(str, x))) for x in list(zip(*x))]] for j,x in enumerate([list(zip(*[[int(i) for i in x.split(":")[1].split(" ") if i != ""] for x in f.read().strip().split("\n")]))]*2)):
        print(f"Part {j+1}:", eval("*".join(str(len([... for i in range(t+1) if d < (i * (t-i))])) for t,d in p)))
