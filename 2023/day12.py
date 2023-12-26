cache = {}


# I have no clue why this works.
def solver(spring: str, records: tuple[int, ...], counter=0):
    if (k := (spring, records, counter)) in cache:
        return cache[k]
    if not spring:
        if len(records) > 1 or counter and not records:
            return False  # Too many records left or there is a counter but no records
        if not counter and not records:  # No counter, No records. We are done
            return True
        return records[0] == counter  # One last record, and this is the last check
    match spring[0]:
        case ".":
            if counter:  # There is a counter counting. We have encountered "."
                if records and records[0] == counter:
                    return solver(spring[1:], records[1:], 0)  # Progress to next state if match
                return False
            return solver(spring[1:], records, 0)
        case "#":
            return solver(spring[1:], records, counter + 1)
        case "?":
            n = solver(spring[1:], records, counter + 1)
            if not counter:
                n += solver(spring[1:], records, 0)
            elif records and records[0] == counter:
                n += solver(spring[1:], records[1:], 0)
            cache[(spring, records, counter)] = n
            return n
    assert False


p1 = p2 = 0
with open("in/d12.txt") as f:
    for s, r in (
        (s.replace("..", ".").replace("..", "."), tuple(map(int, r.split(",")))) for s, r in (x.split() for x in f)
    ):
        cache.clear()
        p1 += solver(s, r)
        cache.clear()
        p2 += solver("?".join([s] * 5), r * 5)
print("Part 1:", p1)
print("Part 2:", p2)
