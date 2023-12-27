from math import lcm

with open("in/d8.txt", "rt") as f:
    strat = tuple(x != "L" for x in f.readline().strip())
    maps = {
        k.strip(): tuple("".join(c for c in s if c.isalpha() or c.isdigit()) for s in v.strip().split(","))
        for k, v in (x.split("=") for x in f if x.strip())
    }

def g(_map: str, _maps: dict[str, tuple[str, ...]], _strat: tuple[bool,...]) -> int:
    i, strat_len = 0, len(_strat)
    while (_map := _maps[_map][_strat[i % strat_len]])[-1] != "Z":
        i += 1
    return i + 1

path_to_z = [g(_m, maps, strat) for _m in sorted(m for m in maps if m[-1] == "A")]

print("Part 1:", path_to_z[0])
print("Part 2:", lcm(*path_to_z))
