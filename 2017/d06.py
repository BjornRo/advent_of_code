with open("in/d06.txt") as f:
    data = tuple(int(x) for x in f.read().split())


def solver(bank: list[int]):
    seen = {}
    cycles = 0
    diff = 0
    while True:
        if (key := tuple(bank)) not in seen:
            seen[key] = cycles
        else:
            diff = cycles - seen[key]
            break

        m = max(bank)
        i = bank.index(m)
        bank[i] = 0
        for j in range(i + 1, i + m + 1):
            bank[j % len(bank)] += 1
        cycles += 1
    return cycles, diff


p1, p2 = solver(list(data))
print(f"Part 1: {p1}")
print(f"Part 2: {p2}")
