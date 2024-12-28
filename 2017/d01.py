with open("in/d01.txt") as f:
    input_data = f.read().rstrip()


def solve(data: str) -> tuple[int, int]:
    part1 = 0
    part2 = 0

    for i in range(len(data)):
        if data[i] == data[(i + 1) % len(data)]:
            part1 += int(data[i])
        if data[i] == data[(i + len(data) // 2) % len(data)]:
            part2 += int(data[i])
    return part1, part2


p1, p2 = solve(input_data)

print(f"Part 1: {p1}")
print(f"Part 2: {p2}")
