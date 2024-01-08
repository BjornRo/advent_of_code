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
start_end = (0, 1), (len(chart) - 1, len(chart[0]) - 2)


def find_paths_dag_dfs(chart: tuple[tuple[int, ...], ...], start: Node2D, end: Node2D):
    graph: Graph = defaultdict(dict)
    next_state: list[State] = [(start, {start}, start)]
    visited_crossings: Visited = set()
    intersection: list[Node2D] = []
    while next_state:
        intersection *= 0
        rc, curr_path, start_path = next_state.pop()
        if rc == end:
            graph[start_path][rc] = len(curr_path) - 1
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


def dfs_imp(graph: Graph, start: Node2D, end: Node2D, max_steps=0):
    next_state: list[tuple[Node2D, Steps, Visited]] = [(start, max_steps, {start})]
    while next_state:
        node, weight, visited = next_state.pop()
        for next_node, next_weight in graph[node].items():
            if next_node not in visited:
                if next_node == end:
                    max_steps = max(weight + next_weight, max_steps)
                    continue
                next_state.append((next_node, weight + next_weight, {*visited, next_node}))
    return max_steps


def dfs_rec(graph: Graph, node: Node2D, end: Node2D, visited=set(), max_steps=0):
    if node == end:
        return max_steps
    visited.add(node)
    steps = 0
    for next_node, weight in graph[node].items():
        if next_node not in visited:
            steps = max(dfs_rec(graph, next_node, end, visited, max_steps + weight), steps)
    visited.remove(node)
    return steps


reduced_graph = find_paths_dag_dfs(chart, *start_end)
print("Part 1:", dfs_rec(reduced_graph, *start_end))
print("  Finished in:", round(time.time() - start_time, 5), "secs")


def dag_to_undirected(chart: Graph, end: Node2D) -> dict[Node2D, dict[Node2D, int]]:
    graph: defaultdict[Node2D, dict[Node2D, int]] = defaultdict(dict)
    for node1, next_nodes in chart.items():
        for node2, weight in next_nodes.items():
            graph[node1][node2], graph[node2][node1] = weight, weight
    prev_end, weight = next(iter(graph[end].items()))  # Optimization
    graph[prev_end] = {end: weight}  # 1. Last intersection always leads to the end
    for v in graph.values():  # 2. If 4 paths, remove lowest weight.
        x = tuple(v.values())
        if len(v) == 4:
            m, c = min(x), tuple(v.items())
            for kk, vv in c:
                if vv == m:
                    v.pop(kk)
                    break  # End optimization
    return graph


# pypy is faster with imperative, cpython is faster with recursion
print("Part 2:", dfs_imp(dag_to_undirected(reduced_graph, start_end[1]), *start_end))
print("  Total time for p1,p2:", round(time.time() - start_time, 5), "secs")
