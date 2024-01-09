from time import perf_counter as time_it

start_it = time_it()

with open("in/d13.txt") as f:
    maps = [[[c == "#" for c in y] for y in x.splitlines() if y] for x in f.read().split("\n\n")]


def mirrors(e: list[list[bool]], t: int) -> int:
    total = 0
    for horizontal in (True, False):
        for i in range(1, len(e)):
            if sum(sum(x != y for x, y in zip(r1, r2)) for r1, r2 in zip(e[i:], e[:i][::-1])) == t:
                total += (i * 100) if horizontal else i
                break
        e = list(zip(*e))
    return total


print("Part 1:", sum(mirrors(e, 0) for e in maps))
print("Part 2:", sum(mirrors(e, 1) for e in maps))
print("Finished in:", round(time_it() - start_it, 4), "secs")
