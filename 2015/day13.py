import re
from collections import defaultdict

table1, table2 = defaultdict(dict), defaultdict(dict)
with open("in/d13.txt") as f:
    for src, gl, v, dst in re.findall(r"([a-zA-Z]+)[a-z\s]+(gain|lose)[a-z\s]+(\d+)[a-z\s]+([a-zA-Z]+)", f.read()):
        table1[src][dst] = int(v) * (1 if gl == "gain" else -1)
        table2[src][dst] = int(v) * (1 if gl == "gain" else -1)
        table2["yes"][dst] = table2[src]["yes"] = 0


def table_fighters(table: dict[str, dict[str, int]]) -> int:
    stack, start, fight_club = [], next(iter(table)), 0
    stack.append((start, [], 0))
    while stack:
        person, visited, cost = stack.pop()
        if person not in visited:
            visited = [*visited, person]
            if set(visited) == table.keys():
                fight_club = max(fight_club, cost + table[start][person] + table[person][start])
                continue
            for next_place, weight in table[person].items():
                stack.append((next_place, visited, weight + cost + table[next_place][person]))
    return fight_club


print("Part 1:", table_fighters(table1))
print("Part 2:", table_fighters(table2))
