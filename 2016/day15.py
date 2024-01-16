def drop_it(discer: tuple[list[int], ...], start: int):
    for i, (n_pos, curr_pos) in enumerate(discer, 1 + start):
        if (curr_pos + i) % n_pos != 0:
            return False
    return True


with open("in/d15.txt") as f:
    discus = tuple([*map(int, (c for c in x.strip().replace(".", "").split() if c.isdigit()))] for x in f)
part1, part2, discard = None, None, (*discus, [11, 0])
for i in range(100_000_000_000):
    if part1 is None and drop_it(discus, i):
        part1 = i
    if part2 is None and drop_it(discard, i):
        part2 = i
    if not (part1 is None or part2 is None):
        break
print("Part 1:", part1)
print("Part 2:", part2)
