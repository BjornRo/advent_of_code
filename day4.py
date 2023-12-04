# Part 1
with open("d4.txt", "rt") as f:
    print(sum((1 << (len(v+h) - len(set(v+h)))) // 2 for v,h in list(map(lambda x: list(map(lambda y: list(filter(lambda z: z, y.strip().split(" "))),x.split(":")[-1].strip().split("|"))), f.read().strip().split("\n")))))

# Part 2
with open("d4.txt", "rt") as f:
    p = f.read().strip().split("\n")
    acc = [1]*len(p)
    for i,j in enumerate(len(v+h) - len(set(v+h)) for v,h in map(lambda x: list(map(lambda y: list(filter(lambda z: z, y.strip().split(" "))),x.split(":")[-1].strip().split("|"))),p)):
        for k in range(j):
            acc[i+k+1] += acc[i]
    print(sum(acc))