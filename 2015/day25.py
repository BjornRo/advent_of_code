with open("in/d25.txt") as f:
    (row, col), c = map(int, "".join(c for c in f.read() if c.isdigit() or c == " ").split()), 20151125
for _ in range((lambda n: (n * (n + 1)) // 2)(row + col - 2) + col - 1):  # Arit sum: 1+2+3+...+n
    c = (c * 252533) % 33554393
print("Part 1:", c)
