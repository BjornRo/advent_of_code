def find_holes(mi: int, ma: int, b: list[list[int]]) -> tuple[tuple[int, int], list[list[int]]]:
    return find_holes(mi, max(b[0][1], ma), b[1:]) if b and (mi <= b[0][0] <= (ma + 1)) else ((mi, ma), b)


with open("in/d20.txt") as f:
    (_a, a), *blocked = sorted([*map(int, x.rstrip().split("-"))] for x in f)
(total_ips, a), b = find_holes(_a, a, blocked)
print("Part 1:", a + 1)
while b:
    (_a, __a), b = find_holes(b[0][0], b[0][1], b[1:])
    total_ips += _a - (a + 1)
    a = __a
print("Part 2:", total_ips + a - ((1 << 32) - 1))
