def find_holes(mi: int, ma: int, b: list[list[int]]):
    return find_holes(mi, max(b[0][1], ma), b[1:]) if b and (mi <= b[0][0] <= (ma + 1)) else ((mi, ma), b)


with open("in/d20.txt") as f:
    a, *blocked = sorted([*map(int, x.rstrip().split("-"))] for x in f)
a, b = find_holes(a[0], a[1], blocked)
print("Part 1:", a[1] + 1)

total_ips = a[0]
while b:
    aa, b = find_holes(b[0][0], b[0][1], b[1:])
    total_ips += aa[0] - (a[1] + 1)
    a = aa
total_ips += a[1] - ((1 << 32) - 1)
print("Part 2:", total_ips)
