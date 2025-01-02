from collections import defaultdict
from typing import cast

type Key = tuple[int, int]
type Value = list[Key]
type Graph = dict[Key, Value]
graph: dict[Key, Value] = defaultdict(list)
start = []

with open("in/d24.txt") as f:
    data = cast(Value, sorted(tuple(sorted(map(int, x.rstrip().split("/")))) for x in f))

for e1 in data:
    if 0 in e1:
        start.append(e1)
    for e2 in data:
        if e1 != e2:
            if e1[0] in e2 or e1[1] in e2:
                graph[e1].append(e2)


def bridge_builder(graph: Graph, bridge: Value, connector: int, bridges: list[Key]) -> int:
    available: Value = []
    for i in graph[bridge[-1]]:
        if connector in i and i not in bridge:
            available.append(i)

    if not available:
        res = sum(a + b for a, b in bridge)
        bridges.append((len(bridge), res))
        return res

    max_val = 0
    for i in available:
        new_conn = i[1] if connector == i[0] else i[0]
        res = bridge_builder(graph, [*bridge, i], new_conn, bridges)
        if res > max_val:
            max_val = res
    return max_val


bridges: list[Key] = []
print(f"Part 1: {max(bridge_builder(graph, [x], x[1], bridges) for x in start)}")
print(f"Part 2: {sorted(bridges, key=lambda x: (x[0], x[1]), reverse=True)[0][1]}")
