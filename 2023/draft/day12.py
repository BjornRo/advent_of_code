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


# spring_len = len(spring)
# record_add1 = [r + 1 for r in records]


# moves = 0
# ends_dot = False
# for i, record in enumerate(records):
#     current_record = records[i]
#     start_range = sum(record_add1[:i])
#     end_range = sum(record_add1[i + 1 :]) + 1  # +1 due to appending "."
#     substring = spring[start_range : spring_len - end_range]
#     print(substring)


# @cache
# def nfa(spring: str, records: tuple[int, ...], counter=0):
#     if not spring:
#         if len(records) > 1 or counter and not records:
#             return False  # Too many records left or there is a counter but no records
#         if not counter and not records:  # No counter, No records. We are done
#             return True
#         return records[0] == counter  # One last record, and this is the last check
#     match spring[0]:
#         case ".":
#             if counter:  # There is a counter counting. We have encountered "."
#                 if records and records[0] == counter:
#                     return nfa(spring[1:], records[1:], 0)  # Progress to next state if match
#                 return False
#             return nfa(spring[1:], records, 0)
#         case "#":
#             return nfa(spring[1:], records, counter + 1)
#         case "?":
#             return nfa(spring[1:], records, counter + 1) + (
#                 nfa(spring[1:], records, 0)
#                 if not counter
#                 else nfa(spring[1:], records[1:], 0)
#                 if records and records[0] == counter
#                 else False
#             )
#     assert False

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
