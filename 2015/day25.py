import re

with open("in/d25.txt") as f:
    row, col = map(int, re.findall(r"\d+", f.read().strip()))

next_code, arit_sum, c = lambda number: (number * 252533) % 33554393, lambda n: (n * (n + 1)) // 2, 20151125
for i in range(arit_sum(row + col - 2) + col - 1):
    c = next_code(c)
print("Part 1:", c)
