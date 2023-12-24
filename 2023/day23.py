import time
from collections import defaultdict

start_time = time.time()
with open("in/d23.txt") as f:
    chart: tuple[str, ...] = tuple(x.strip() for x in f)

seo = (0, 1), (len(chart) - 1, len(chart[0]) - 2), (-1, 1)
Row, Col, Steps = int, int, int
Node2D = tuple[Row, Col]


def dfs(graph: tuple[str, ...], start: Node2D, end: Node2D, oob: Node2D, max_steps=0) -> int:
    stack = [(start, max_steps, [start, oob])]
    while stack:
        (row, col), steps, visited = stack.pop()
        for dir, nrow, ncol in ("^", row + 1, col), ("v", row - 1, col), ("<", row, col + 1), (">", row, col - 1):
            if (nrow, ncol) == end:
                max_steps = max(len(visited) - 1, max_steps)
                continue
            if (value := graph[nrow][ncol]) != "#" and (nrow, ncol) not in visited:
                if value == "." or dir != value:
                    stack.append(((nrow, ncol), steps + 1, [(nrow, ncol), *visited]))
    return max_steps


print("Part 1:", dfs(chart, *seo))
print("  Finished in:", round(time.time() - start_time, 4), "secs")

""" Part 2 """
CurrentPos, CurrPath, StartPathPos, Visited = Node2D, list[Node2D], Node2D, list[Node2D]
Graph, State = dict[tuple[Node2D, Node2D], Steps], tuple[CurrentPos, CurrPath, StartPathPos]


def find_paths_dfs(chart: tuple[str, ...], start: Node2D, end: Node2D, oob: Node2D):
    graph: Graph = {}
    next_state: list[State] = [(start, [start, oob], start)]
    visited_crossings: set[Node2D] = set()
    intersection: list[tuple[int, int]] = []
    while next_state:
        (row, col), curr_path, start_path = next_state.pop()
        if (row, col) == end:
            graph[(start_path, (row, col))] = len([x for x in curr_path if x != oob]) - 1
            continue
        for nrow, ncol in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
            if chart[nrow][ncol] != "#" and (nrow, ncol) not in curr_path:
                intersection.append((nrow, ncol))
        at_intersect = len(intersection) >= 2
        if at_intersect:
            gkey = (start_path, (row, col))  # If a frontier comes from the other direction
            if not (gkey in graph or gkey[::-1] in graph):  # while another waits at intersect+1.
                graph[gkey] = len([x for x in curr_path if x != oob]) - 1  # From intersection to intersection
            if (row, col) in visited_crossings:  # No need to revisit a crossing
                intersection *= 0  # Clear since we continue
                continue
            visited_crossings.add((row, col))
            start_path = (row, col)  # Start now from this new intersection
        while intersection and (nrowcol := intersection.pop()):
            if at_intersect:  # currpos_node, currpath_set, startpath_node
                next_state.append((nrowcol, [nrowcol, start_path], start_path))
            else:  # Else continue journey with the frontier
                next_state.append((nrowcol, [nrowcol, *curr_path], start_path))
    return graph


def adjacency_list(edges: list[tuple[Node2D, Node2D, Steps]], end: Node2D) -> dict[Node2D, dict[Node2D, int]]:
    graph: defaultdict[Node2D, dict[Node2D, int]] = defaultdict(dict)
    for node1, node2, weight in edges:
        graph[node1][node2], graph[node2][node1] = weight, weight
    prev_end, weight = next(iter(graph[end].items())) # Optimization
    graph[prev_end] = {end: weight} # Last intersection always leads to the end
    for v in graph.values(): # If 4 paths, remove lowest weight.
        x = tuple(v.values())
        if len(v) == 4:
            m, c = min(x), tuple(v.items())
            for kk, vv in c:
                if vv == m:
                    v.pop(kk)
                    break  # End optimization
    return dict(graph)


def dfs2_imp(graph: dict[Node2D, dict[Node2D, int]], start: Node2D, end: Node2D, max_steps=0):
    next_state: list[tuple[Row, Col, Steps, Visited]] = [(*start, max_steps, [start])]
    while next_state:
        row, col, weight, visited = next_state.pop()
        for next_node, next_weight in graph[(row, col)].items():
            if next_node == end:
                max_steps = max(weight + next_weight, max_steps)
                continue
            if next_node not in visited:
                next_state.append((*next_node, weight + next_weight, [next_node, *visited]))
    return max_steps


def dfs2_rec(graph: dict[Node2D, dict[Node2D, int]], start: Node2D, end: Node2D, visited=set(), max_steps=0):
    if start == end:
        return max_steps
    visited.add(start)
    steps = 0
    for next_node, next_weight in graph[start].items():
        if next_node not in visited:
            steps = max(dfs2_rec(graph, next_node, end, visited, max_steps + next_weight), steps)
    visited.remove(start)
    return steps


print("Part 2:", dfs2_imp(adjacency_list([(*a, w) for a, w in find_paths_dfs(chart, *seo).items()], seo[1]), *seo[:2]))
print("  Total time for p1,p2:", round(time.time() - start_time, 4), "secs")
