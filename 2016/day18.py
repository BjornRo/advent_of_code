def its_a_bait(rows: int, total: int):
    trapper, trap_len = [[False, False] + its_a_trap + [False, False]], len(its_a_trap) + 2
    for i in range(rows - 1):
        next_trap = [False, False]
        for j in range(1, trap_len):
            match trapper[i][j : j + 3]:
                case [True, True, False] | [False, True, True] | [False, False, True] | [True, False, False]:
                    next_trap.append(True)
                case _:
                    next_trap.append(False)
        next_trap[trap_len:] = False, False
        total += sum(not c for c in next_trap) - 4
        trapper.append(next_trap)
    return total


with open("in/d18.txt") as f:
    its_a_trap = [x == "^" for x in f.read().rstrip()]
print("Part 1:", its_a_bait(40, sum(not c for c in its_a_trap)))
print("Part 2:", its_a_bait(400_000, sum(not c for c in its_a_trap)))
