with open("d13.txt") as f:
    maps = [[[c == "#" for c in y] for y in x.splitlines() if y] for x in f.read().split("\n\n")]


def mirrors(e: list[list[bool]], t: int) -> int:
    total = 0
    for horizontal in (True, False):
        for i in range(1, len(e)):
            _rws = zip(e[i:], e[:i][::-1])
            if sum(sum(0 if x == y else 1 for x, y in zip(r1, r2)) for r1, r2 in _rws) == t:
                total += (i * 100) if horizontal else i
                break
        if horizontal:  # optimization
            e = list(zip(*e))
    return total


print("Part 1:", sum(mirrors(e, 0) for e in maps))
print("Part 2:", sum(mirrors(e, 1) for e in maps))
