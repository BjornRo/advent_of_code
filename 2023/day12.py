def springtime(spring: str, records: tuple[int, ...], cache: dict, counter=0):  # I have no clue why this works.
    if (k := (spring, records, counter)) in cache:
        return cache[k]
    if not spring:
        if len(records) > 1 or (counter and not records):
            return False  # Too many records left or there is a counter but no records
        if not (counter or records):  # No counter, No records. We are done
            return True
        return records[0] == counter  # One last record, and this is the last check
    match spring[0]:
        case ".":
            if counter:  # There is a counter counting. We have encountered "."
                if records and records[0] == counter:
                    return springtime(spring[1:], records[1:], cache, 0)  # Progress to next state if match
                return False
            return springtime(spring[1:], records, cache, 0)
        case "?":
            n = springtime(spring[1:], records, cache, counter + 1)
            if not counter:
                n += springtime(spring[1:], records, cache, 0)
            elif records and records[0] == counter:
                n += springtime(spring[1:], records[1:], cache, 0)
            cache[(spring, records, counter)] = n
            return n
    return springtime(spring[1:], records, cache, counter + 1)


p1 = p2 = 0
with open("in/d12.txt") as f:
    for s, r in ((s, tuple(map(int, r.split(",")))) for s, r in (x.split() for x in f)):
        s = s.replace("..", ".").replace("..", ".")
        p1, p2 = p1 + springtime(s, r, {}), p2 + springtime("?".join([s] * 5), r * 5, {})
print("Part 1:", p1)
print("Part 2:", p2)
