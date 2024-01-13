from collections import Counter

with open("in/d6.txt") as f:
    hidden_msg = tuple(Counter(col).most_common() for col in (zip(*(x.rstrip() for x in f))))

print("Part 1:", "".join(c[0][0] for c in hidden_msg))
print("Part 2:", "".join(c[-1][0] for c in hidden_msg))
