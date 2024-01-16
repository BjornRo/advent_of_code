def its_a_bait(rows: int, total: int, next_trap=[False, False]):
    trapper, (t_len, tless, tr_len) = [False, False, *its_a_trap, False, False], (len(its_a_trap) + i for i in range(3))
    for _ in range(rows - 1):
        for j in range(1, tless):
            match trapper[j : j + 3]:
                case [True, True, False] | [False, True, True] | [False, False, True] | [True, False, False]:
                    next_trap.append(True)
                case _:
                    next_trap.append(False)
                    if j <= t_len:
                        total += 1
        trapper[2:tr_len] = next_trap[2:tr_len]
        next_trap[2:] *= 0
    return total


with open("in/d18.txt") as f:
    its_a_trap = [x == "^" for x in f.read().rstrip()]
print("Part 1:", its_a_bait(40, sum(not c for c in its_a_trap)))
print("Part 2:", its_a_bait(400_000, sum(not c for c in its_a_trap)))
