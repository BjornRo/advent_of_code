with open("in/d20.txt") as f:
    blocked = sorted(sorted(map(int, x.rstrip().split("-"))) for x in f)


def find_holes(curr_min: int, curr_max: int, blocked: list[list[int]]):
    if not (blocked and (curr_min <= blocked[0][0] <= (curr_max + 1))):
        return (curr_min, curr_max), blocked  # Min,max and rest of the ranges
    return find_holes(curr_min, max(blocked[0][1], curr_max), blocked[1:])


a, b = find_holes(blocked[0][0], blocked[0][1], blocked[1:])
print("Part 1:", a[1] + 1)

total_ips = 0  # Assuming first range starting with 0
while b:
    aa, b = find_holes(b[0][0], b[0][1], b[1:])
    total_ips += aa[0] - (a[1] + 1)
    a = aa
total_ips += a[1] - ((1 << 32) - 1)
print("Part 2:", total_ips)
