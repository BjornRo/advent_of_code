from collections import deque
from itertools import permutations


def fried(floor: tuple[str, ...], elevator: int, ignore: tuple = (), append: tuple = ()) -> bool:
    if elevator == MAX_LESS:
        return True
    gens, micro, powered = set(), set(), False
    for e in (c for c in floor if c not in ignore):
        (micro if e[1] == "m" else gens).add(e[0])
    for e in append:
        (micro if e[1] == "m" else gens).add(e[0])
    for m in tuple(micro):
        if m in gens:
            powered = True
            micro.remove(m)
            gens.remove(m)
    return not ((powered and micro) or (gens and micro))


def deep_fried(floor1: tuple[str, ...], elevator1: int, floor2: tuple[str, ...], elevator2: int, elem=()) -> bool:
    return fried(floor1, elevator1, ignore=elem) and fried(floor2, elevator2, append=elem)


def levels(start: tuple[tuple[str, ...], ...], min_steps=1 << 32):
    Elevator, Steps, Floors = int, int, tuple[tuple[str, ...], ...]
    END, MLEN, vis, State = sum(1 for row in start for _ in row), len(start), set(), tuple[Elevator, Steps, Floors]
    stack: deque[State] = deque([(0, 0, start)])
    while stack:
        lvl, steps, floors = stack.popleft()
        if steps >= min_steps or (k := hash((lvl, floors))) in vis:
            continue
        vis.add(k)  # Visited requires floors to be sorted, otherwise it appears as a new state.
        if len(floors[-1]) == END:
            if steps < min_steps:
                min_steps = steps
            continue
        if 0 <= (next_lvl := lvl - 1) < MLEN:
            curr_floor, next_floor = floors[lvl], floors[next_lvl]
            for e in curr_floor:
                if deep_fried(curr_floor, lvl, next_floor, next_lvl, (e,)):
                    clvl, nlvl = tuple(x for x in curr_floor if x != e), tuple(sorted((*next_floor, e)))
                    (prev, pfloor), (succ, sfloor) = sorted(((lvl, clvl), (next_lvl, nlvl)))
                    stack.append((next_lvl, steps + 1, (*floors[:prev], pfloor, sfloor, *floors[succ + 1 :])))
        if 0 <= (next_lvl := lvl + 1) < MLEN:
            curr_floor, next_floor = floors[lvl], floors[next_lvl]
            for p in permutations(curr_floor, 2):  # Return empty if less than n elems
                if fried(p, 0) and deep_fried(curr_floor, lvl, next_floor, next_lvl, p):
                    clvl, nlvl = tuple(x for x in curr_floor if x not in p), tuple(sorted((*next_floor, *p)))
                    (prev, pfloor), (succ, sfloor) = sorted(((lvl, clvl), (next_lvl, nlvl)))
                    stack.append((next_lvl, steps + 1, (*floors[:prev], pfloor, sfloor, *floors[succ + 1 :])))
    return min_steps


mopper = lambda string: tuple(sorted("".join(c[0] for c in s.split()[:2]) for s in string.rstrip().split("a ")[1:]))
with open("in/d11.txt") as f:
    init_floors1 = tuple(mopper(s) if i != 3 else () for i, s in enumerate(f))
MAX_LESS = len(init_floors1) - 1
print("Part 1:", levels(init_floors1))
print("Part 2:", levels((tuple(sorted((*init_floors1[0], "eg", "em", "dg", "dm"))), *init_floors1[1:])))
