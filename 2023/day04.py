# Part 1
with open("d4.txt", "rt") as f:
    print("Part 1:", sum((1 << (len(v+h) - len(set(v+h)))) // 2 for v,h in list(map(lambda x: list(map(lambda y: list(filter(lambda z: z, y.strip().split(" "))),x.split(":")[-1].strip().split("|"))), f.read().strip().split("\n")))))

# Part 2
with open("d4.txt", "rt") as f:
    s = lambda x: map(lambda y: list(filter(lambda z: z, y.split(" "))), x.split(":")[-1].split("|"))
    a = f.read().strip().split("\n")
    d = [1] * len(a)
    for i,j in enumerate(len(v+h) - len(set(v+h)) for v,h in map(s, a)):
        for k in range(j):
            d[i+k+1] += d[i]
    print("Part :", sum(d))
