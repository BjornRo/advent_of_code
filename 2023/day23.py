import time
from collections import defaultdict

start_time = time.time()
with open("in/d23.txt") as f:
    _m = {"#": 0, ".": 1, "^": 2, "v": 3, "<": 4, ">": 5}
    chart: tuple[tuple[int, ...], ...] = tuple(tuple(_m[c] for c in x.strip()) for x in f)

Row, Col, Steps = int, int, int
Node2D = tuple[Row, Col]
CurrentPos, StartPathPos, Visited = Node2D, Node2D, set[Node2D]
Graph, State = dict[Node2D, dict[Node2D, int]], tuple[CurrentPos, Visited, StartPathPos]
START, END = (0, 1), (len(chart) - 1, len(chart[0]) - 2)


def find_paths_dag_dfs(chart: tuple[tuple[int, ...], ...]):
    graph: Graph = defaultdict(dict)
    next_state: list[State] = [(START, {START}, START)]
    visited_crossings: Visited = set()
    intersection: list[Node2D] = []
    while next_state:
        intersection *= 0
        rc, curr_path, start_path = next_state.pop()
        if rc == END:  # Optimization, "is" is faster than "=="
            graph[start_path][END] = len(curr_path) - 1
            continue
        (row, col), count_cross = rc, 0
        for dir, nrow, ncol in (2, row + 1, col), (3, row - 1, col), (4, row, col + 1), (5, row, col - 1):
            if (value := chart[nrow][ncol]) and (k := (nrow, ncol)) not in curr_path:
                count_cross += 1  # Happy accident that "-1" will select the other side which is a wall :)
                if dir != value:
                    intersection.append(k)
        at_intersect = count_cross >= 2
        if at_intersect:
            graph[start_path][rc] = len(curr_path) - 1
            if rc in visited_crossings:  # No need to revisit a crossing
                continue
            visited_crossings.add(rc)
            start_path = rc
        for nrowcol in intersection:
            if at_intersect:
                curr_path = {start_path, nrowcol}
            else:
                curr_path.add(nrowcol)
            next_state.append((nrowcol, curr_path, start_path))
    return graph


def dfs_imp(graph: Graph, max_steps=0):
    next_state: list[tuple[Node2D, Steps, Visited]] = [(START, max_steps, {START})]
    while next_state:
        node, weight, visited = next_state.pop()
        for next_node, next_weight in graph[node].items():
            if next_node not in visited:
                if next_node is END:
                    if (result := weight + next_weight) > max_steps:
                        max_steps = result
                    continue
                next_state.append((next_node, weight + next_weight, {*visited, next_node}))
    return max_steps


def dfs_rec(graph: Graph, node: Node2D, visited=set(), steps=0):
    if node is END:
        return steps
    visited.add(node)
    max_steps = 0
    for next_node, weight in graph[node].items():
        if next_node not in visited:
            if (result := dfs_rec(graph, next_node, visited, steps + weight)) > max_steps:
                max_steps = result
    visited.remove(node)
    return max_steps


reduced_graph = find_paths_dag_dfs(chart)
print("Part 1:", dfs_imp(reduced_graph))
print("  Finished in:", round(time.time() - start_time, 5), "secs")


def dag_to_undirected(chart: Graph) -> dict[Node2D, dict[Node2D, int]]:
    graph: defaultdict[Node2D, dict[Node2D, int]] = defaultdict(dict)
    for node1, next_nodes in chart.items():
        for node2, weight in next_nodes.items():
            graph[node1][node2] = graph[node2][node1] = weight
    prev_end, weight = next(iter(graph[END].items()))  # Optimization
    graph[prev_end] = {END: weight}  # 1. Last intersection always leads to the end
    for v in graph.values():  # 2. If 4 paths, remove lowest weight.
        if len(v) == 4:
            x = v.values()
            m = min(x)
            for kk, vv in zip(v, x):
                if vv == m:
                    v.pop(kk)
                    break  # End optimization
    return graph


# pypy is faster with imperative, cpython is faster with recursion
print("Part 2:", dfs_rec(dag_to_undirected(reduced_graph), START))
print("  Total time for p1,p2:", round(time.time() - start_time, 5), "secs")
