from collections import Counter

with open("in/d6.txt") as f:
    p1, p2 = zip(*((c[0][0], c[-1][0]) for c in (Counter(y).most_common() for y in zip(*(x.rstrip() for x in f)))))

print("Part 1:", "".join(p1))
print("Part 2:", "".join(p2))
