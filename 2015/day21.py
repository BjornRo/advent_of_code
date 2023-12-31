import itertools as it
from re import findall as fa

_weapons = """
Dagger        8     4       0
Shortsword   10     5       0
Warhammer    25     6       0
Longsword    40     7       0
Greataxe     74     8       0
"""
_armors = """
Leather      13     0       1
Chainmail    31     0       2
Splintmail   53     0       3
Bandedmail   75     0       4
Platemail   102     0       5
"""
_rings = """
Damage +1    25     1       0
Damage +2    50     2       0
Damage +3   100     3       0
Defense +1   20     0       1
Defense +2   40     0       2
Defense +3   80     0       3
"""

parse = lambda ix: {(b, c): a for x in ix.strip().split("\n") for a, b, c in [list(map(int, fa(r"\s\d+", x)))]}
wps, ars, rgs = parse(_weapons), parse(_armors) | {(0, 0): 0}, parse(_rings) | {(0, 0): 0}

with open("in/d21.txt") as f:
    bhp, bdmg, barm = (int(x.split(": ")[1]) for x in f.read().strip().split("\n"))


def arena(least_gold=float("inf"), max_gold=0):
    for w, a, (r1, r2) in it.product(wps, ars, it.permutations((*rgs, (0, 0)), 2)):
        (fdmg, farm), gold = map(sum, zip(*(w, a, r1, r2))), wps[w] + ars[a] + rgs[r1] + rgs[r2]
        freal_dmg, breal_dmg = max(0, fdmg - barm), max(0, bdmg - farm)
        if freal_dmg:
            fhp, bohp = 100, bhp
            while True:
                if (bohp := bohp - freal_dmg) <= 0:
                    least_gold = min(least_gold, gold)
                    break
                if (fhp := fhp - breal_dmg) <= 0:
                    max_gold = max(max_gold, gold)
                    break
    return int(least_gold), max_gold


print("Part 1: {}\nPart 2: {}".format(*arena()))
