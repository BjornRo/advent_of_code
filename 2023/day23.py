from collections import defaultdict

with open("in/d23.txt") as f:
    chart: tuple[str, ...] = tuple(x.strip() for x in f)

seo = (0, 1), (len(chart) - 1, len(chart[0]) - 2), (-1, 1)
Row, Col, Steps, Visited = int, int, int, set
Node2D = tuple[Row, Col]
Frontier = tuple[Node2D, Steps]


def bfs(graph: tuple[str, ...], start: Node2D, end: Node2D, oob: Node2D, max_steps=0) -> int:
    current_epoch: dict[Frontier, Visited] = {(start, 0): {start, oob}}
    next_epoch: dict[Frontier, Visited] = current_epoch.copy()  # Just as a starter. Does not matter
    while next_epoch:
        next_epoch.clear()
        for ((row, col), steps), visited in current_epoch.items():
            for dir, nrow, ncol in ("^", row + 1, col), ("v", row - 1, col), ("<", row, col + 1), (">", row, col - 1):
                if (nrow, ncol) == end:
                    max_steps = max(len(visited) - 1, max_steps)
                    continue
                if (value := graph[nrow][ncol]) != "#" and (nrow, ncol) not in visited:
                    if value == "." or dir != value:
                        nvisited = visited.copy()
                        nvisited.add((nrow, ncol))
                        next_epoch[((nrow, ncol), steps + 1)] = nvisited
        current_epoch.clear()
        current_epoch.update(next_epoch)
    return max_steps


print("Part 1:", bfs(chart, *seo))

""" Part 2 """

CurrentPos, CurrPath, StartPathPos = Node2D, set, Node2D
Graph, State = dict[tuple[Node2D, Node2D], Steps], tuple[CurrentPos, CurrPath, StartPathPos]


def find_paths(chart: tuple[tuple[bool, ...], ...], start: Node2D, end: Node2D, oob: Node2D):
    graph: Graph = {}
    next_state: list[State] = [(start, {start, oob}, start)]
    visited_crossings: set[Node2D] = set()
    intersection: list[tuple[int, int]] = []
    while next_state:
        (row, col), curr_path, start_path = next_state.pop()
        if (row, col) == end:
            graph[(start_path, (row, col))] = len(curr_path - {oob}) - 1
            continue
        for nrow, ncol in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
            nrowcol = nrow, ncol
            if chart[nrow][ncol] >= 1 and nrowcol not in curr_path:
                intersection.append(nrowcol)
        at_intersect = len(intersection) >= 2
        if at_intersect:
            gkey = (start_path, (row, col))  # If a frontier comes from the other direction
            if not (gkey in graph or gkey[::-1] in graph):  # while another waits at intersect+1.
                graph[gkey] = len(curr_path - {oob}) - 1  # From intersection to intersection
            if (row, col) in visited_crossings:  # No need to revisit a crossing
                intersection *= 0  # Clear since we continue
                continue
            visited_crossings.add((row, col))
            start_path = (row, col)  # Start now from this new intersection
        for nrowcol in intersection:
            if at_intersect:  # currpos_node, currpath_set, startpath_node
                next_state.append((nrowcol, {nrowcol, start_path}, start_path))
            else:  # Else continue journey with the frontier
                ncurr_path = curr_path.copy()
                ncurr_path.add(nrowcol)
                next_state.append((nrowcol, ncurr_path, start_path))
        intersection *= 0
    return graph


def adjacency_list(edge_list: list[tuple[Node2D, Node2D, Steps]]) -> dict[Node2D, dict[Node2D, int]]:
    graph: defaultdict[Node2D, dict[Node2D, int]] = defaultdict(dict)
    for node1, node2, weight in edge_list:
        graph[node1][node2], graph[node2][node1] = weight, weight
    return dict(graph)


def dfs(graph: dict[Node2D, dict[Node2D, int]], start: Node2D, end: Node2D, max_steps=0):
    next_state: list[tuple[Frontier, Visited]] = [((start, 0), {start})]
    while next_state:
        (node, weight), visited = next_state.pop()
        for next_node, next_weight in graph[node].items():
            if next_node == end:
                max_steps = max(weight + next_weight, max_steps)
                continue
            if next_node not in visited:
                nvisited = visited.copy()
                nvisited.add(next_node)
                next_state.append(((next_node, weight + next_weight), nvisited))
    return max_steps


plan = tuple(tuple(c != "#" for c in x) for x in chart)
print("Part 2:", dfs(adjacency_list([(*a, w) for a, w in sorted(find_paths(plan, *seo).items())]), *seo[:2]))
