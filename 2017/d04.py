from collections import Counter

with open("in/d04.txt") as f:
    data = [x.strip().split(" ") for x in f]

f = lambda x: Counter(x).most_common(1)[0][1] == 1

print(f"Part 1: {sum(1 for x in data if f(x))}")
print(f"Part 2: {sum(1 for x in data if f(map(lambda y: "".join(sorted(y)), x)))}")
