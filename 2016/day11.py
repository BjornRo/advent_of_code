from collections import deque


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


def deep_fried(cf: tuple[str, ...], cl: int, nf: tuple[str, ...], nl: int, elem: tuple, ofloors: tuple):
    if fried(cf, cl, ignore=elem) and fried(nf, nl, append=elem):
        (p, pf), (s, sf) = sorted(((cl, tuple(x for x in cf if x not in elem)), (nl, tuple(sorted((*nf, *elem))))))
        return (*ofloors[:p], pf, sf, *ofloors[s + 1 :])


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
        if 0 <= (nlvl := lvl - 1) < MLEN:
            for e in floors[lvl]:
                if (flrs := deep_fried(floors[lvl], lvl, floors[nlvl], nlvl, (e,), floors)) is not None:
                    stack.append((nlvl, steps + 1, flrs))
        if 0 <= (nlvl := lvl + 1) < MLEN:
            cfloor, nfloor = floors[lvl], floors[nlvl]
            for i, a in enumerate(cfloor[:-1]):
                for b in cfloor[i + 1 :]:
                    if fried((a, b), 0) and (flrs := deep_fried(cfloor, lvl, nfloor, nlvl, (a, b), floors)) is not None:
                        stack.append((nlvl, steps + 1, flrs))
    return min_steps


mopper = lambda string: tuple(sorted("".join(c[0] for c in s.split()[:2]) for s in string.rstrip().split("a ")[1:]))
with open("in/d11.txt") as f:
    init_floors1 = tuple(mopper(s) if i != 3 else () for i, s in enumerate(f))
MAX_LESS = len(init_floors1) - 1
print("Part 1:", levels(init_floors1))
print("Part 2:", levels((tuple(sorted((*init_floors1[0], "eg", "em", "dg", "dm"))), *init_floors1[1:])))
