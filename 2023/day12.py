from itertools import product


def valid(spring: str, records: list[int]) -> bool:
    total_count = []
    count = 0
    for s in spring:
        if s == ".":
            if count:
                total_count.append(count)
            count = 0
        else:
            count += 1
    if count:
        total_count.append(count)
    return records == total_count


def solver(spring: str, records: list[int]) -> int:
    val = 0
    spring_list = []
    qdot = "#."
    for ptup in product((True, False), repeat=spring.count("?")):
        ip = 0
        js = 0
        slen = len(spring)
        while js < slen:
            c = spring[js]
            if c == "?":
                c = qdot[ptup[ip]]
                ip += 1
            spring_list.append(c)
            js += 1
        val += valid("".join(spring_list), records)
        spring_list.clear()
    return val


with open("in/d12.txt") as f:
    infile = [(s.strip(), list(map(int, r.split(",")))) for s, r in (x.split() for x in f if x.strip())]


n = 0
for s, r in infile:
    n += solver(s, r)
print("Part 1:", n)


# Just as a curiosity to see how it worked. Pretty neat. No submission obviously.
# https://old.reddit.com/r/adventofcode/comments/18ge41g/2023_day_12_solutions/kd3rclt/
RecordIndex = int
CountSprings = int
FindDots = bool
State = tuple[RecordIndex, CountSprings, FindDots]

from collections import defaultdict


def match_string(spring: str, records: list[int]):
    current_states: dict[State, int] = {(0, 0, False): 1}
    next_states: defaultdict[State, int] = defaultdict(int)
    record_len = len(records)
    for c in spring:
        for (record_index, count_springs, find_dots), val in current_states.items():
            if c in {"#", "?"} and record_index < record_len and not find_dots:
                if c == "?" and not count_springs:
                    next_states[(record_index, count_springs, find_dots)] += val
                count_springs += 1
                if count_springs == records[record_index]:
                    record_index += 1
                    count_springs, find_dots = 0, True
                next_states[(record_index, count_springs, find_dots)] += val
            elif c in {".", "?"} and not count_springs:
                next_states[(record_index, count_springs, False)] += val
        current_states.clear()
        current_states.update(next_states)
        next_states.clear()
    total = 0
    for (record_index, count_springs, find_dots), val in current_states.items():
        if record_index == record_len:
            total += val
    return total


# n = 0
# for s, r in infile:
#     n += match_string("?".join([s] * 5), r * 5)
# print("Part 2:", n)
