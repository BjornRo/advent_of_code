import re
from collections import defaultdict

graph = defaultdict(set)

with open("in/d12.txt") as f:
    for row in f:
        pid, *pids = map(int, re.findall(r"\d+", row))
        graph[pid].update(pids)
        for p in pids:
            graph[p].add(pid)


def solver(graph: dict[int, set[int]]) -> tuple[int, int]:
    pid0 = 0
    groups = 0
    while len(graph) != 0:
        visited = set()
        stack = [next(iter(graph))]
        while stack:
            pid = stack.pop()

            if pid in visited:
                continue
            visited.add(pid)

            stack.extend(graph[pid])
        groups += 1
        if 0 in visited:
            pid0 = len(visited)
        for v in visited:
            graph.pop(v)
    return pid0, groups


p1, p2 = solver(graph)
print(f"Part 1: {p1}")
print(f"Part 2: {p2}")
