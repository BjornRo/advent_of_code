def pp(s: set):  # Pretty print path
    zeros = [list(map(str, x)) for x in chart]  # type:ignore
    for row, col in s:
        if row == -1:
            continue
        zeros[row][col] = "x"
    for r in zeros:
        print("".join(r))


from enum import IntEnum


class D(IntEnum):
    L = 2
    R = 3
    U = 4
    D = 5


with open("in/d23.txt") as f:
    chart = tuple(tuple(map({"#": 0, ".": 1, "<": D.L, ">": D.R, "v": D.D, "^": D.U}.get, x.strip())) for x in f)


START, END, OOB = (0, 1), (len(chart) - 1, len(chart[0]) - 2), (-1, 1)


def find_paths_dag_dfs(chart: tuple[tuple[int, ...], ...], start: Node2D, end: Node2D, oob: Node2D):
    xstate = tuple[Node2D, Node2D, int]
    graph: Graph = {}
    next_state: list[xstate] = [(start, start, 0)]
    visited: set[Node2D] = set((start, oob))
    visited_crossings = set()
    intersection: list[tuple[int, int, int]] = []
    while next_state:
        intersection *= 0
        (row, col), start_path, steps = next_state.pop()
        if (row, col) == end:
            n1, n2 = sorted((start_path, (row, col)))
            graph[(n1, n2)] = steps
            continue
        visited.add((row, col))
        for dir, nrow, ncol in (2, row + 1, col), (3, row - 1, col), (4, row, col + 1), (5, row, col - 1):
            if chart[nrow][ncol] and (k := (nrow, ncol)) not in visited:
                intersection.append((dir, nrow, ncol))
        at_intersect = len(intersection) >= 2
        if at_intersect:
            n1, n2 = sorted((start_path, (row, col)))
            if not (key := (n1, n2)) in graph:  # while another waits at intersect+1.
                graph[key] = steps
            start_path = (row, col)  # Start now from this new intersection
            steps = 0
        for dir, nrow, ncol in intersection:
            if dir != chart[nrow][ncol]:
                next_state.append(((nrow, ncol), start_path, steps + 1))
    return graph


# for i in chart:
#     print("".join(map(str, i)))

CurrDir = D
Steps = int
Row = int
Col = int
Visited = set
WalkID = int
Hiker = tuple[Row, Col, Steps]
Node = tuple[int, int]


def pp(s: set):
    zeros = [list(map(str, x)) for x in chart]  # type:ignore
    for row, col in s:
        if row == -1:
            continue
        zeros[row][col] = "x"
    for r in zeros:
        print("".join(r))


def find_paths_dfs(chart: tuple[tuple[int, ...], ...], start: Node2D, end: Node2D, oob: Node2D):
    graph: Graph = {}
    next_state: list[State] = [(start, [start, oob], start)]
    visited_crossings: set[Node2D] = set()
    intersection: list[Node2D] = []
    while next_state:
        intersection *= 0
        (row, col), curr_path, start_path = next_state.pop()
        if (row, col) == end:
            graph[(start_path, (row, col))] = len([x for x in curr_path if x != oob]) - 1
            continue
        for nrow, ncol in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
            if chart[nrow][ncol] and (nrow, ncol) not in curr_path:
                intersection.append((nrow, ncol))
        at_intersect = len(intersection) >= 2
        if at_intersect:
            gkey = (start_path, (row, col))  # If a frontier comes from the other direction
            if not (gkey in graph or gkey[::-1] in graph):  # while another waits at intersect+1.
                graph[gkey] = len([x for x in curr_path if x != oob]) - 1  # From intersection to intersection
            if (row, col) in visited_crossings:  # No need to revisit a crossing
                continue
            visited_crossings.add((row, col))
            start_path = (row, col)  # Start now from this new intersection
        for nrowcol in intersection:
            next_state.append((nrowcol, [nrowcol, *([start_path] if at_intersect else curr_path)], start_path))
    return graph


def find_nodef(graph: tuple[tuple, ...] | list[list[int]], last_intersection: tuple[int, int]):
    max_steps = 0
    next_state: list[tuple[Hiker, Visited]] = [((*START, 0), {START, OOB})]
    while next_state:
        (row, col, steps), visited = next_state.pop()
        for ndir, nrow, ncol in (D.U, row + 1, col), (D.D, row - 1, col), (D.L, row, col + 1), (D.R, row, col - 1):
            if (row, col) == last_intersection and ndir != D.U:
                continue
            nrowcol = nrow, ncol
            if nrowcol == END:
                if steps + 1 > max_steps:
                    max_steps = steps + 1
                    print(max_steps)
                continue
            if graph[nrow][ncol] >= 1 and nrowcol not in visited:
                nvisited = visited.copy()
                nvisited.add(nrowcol)
                next_state.append(((nrow, ncol, steps + 1), nvisited))
    return max_steps


def find_last(graph: tuple[tuple, ...] | list[list[int]]) -> Node:
    next_state: list[tuple[Node, Visited]] = [(END, {END, (len(chart), len(chart[0]) - 2)})]
    intersection: list[Node] = []
    while next_state:
        (row, col), visited = next_state.pop()
        for nrow, ncol in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
            nrowcol = nrow, ncol
            if nrowcol not in visited and graph[nrow][ncol] >= 1:
                intersection.append(nrowcol)
        if len(intersection) >= 2:
            return row, col
        for nrowcol in intersection:
            nvisited = visited.copy()
            nvisited.add(nrowcol)
            next_state.append((nrowcol, nvisited))
        intersection.clear()
    return (-1, -1)


print(find_nodef(chart, find_last(chart)))


from enum import IntEnum


class D(IntEnum):
    L = 2
    R = 3
    U = 4
    D = 5


with open("in/e23.txt") as f:
    chart = tuple(
        tuple(map(lambda c: {"#": 0, ".": 1, "<": D.L, ">": D.R, "v": D.D, "^": D.U}[c], x.strip())) for x in f
    )

START, END, OOB = (0, 1), (len(chart) - 1, len(chart[0]) - 2), (-1, 1)

# for i in chart:
#     print("".join(map(str, i)))

Node = tuple[int, int]
Weight = int
Graph = dict[Node, tuple[Node, Weight]]  # start to stop
CurrPath = set
StartPathPos = Node
CurrentPos = Node
State = tuple[CurrentPos, CurrPath, StartPathPos]


def pp(s: set):
    zeros = [list(map(str, x)) for x in chart]  # type:ignore
    for row, col in s:
        if row == -1:
            continue
        zeros[row][col] = "x"
    for r in zeros:
        print("".join(r))


def find_paths(chart: tuple[tuple[int]]):
    graph: Graph = {}
    current_state: list[State] = [(START, {START, OOB}, START)]  # Take this into consideration when calc steps
    next_state: list[State] = current_state.copy()
    intersection: list[tuple[int, int]] = []
    while next_state:
        next_state.clear()
        for (row, col), curr_path, start_path in current_state:
            if (row, col) == END:
                graph[start_path] = ((row, col), len(curr_path))
                continue
            for _, nrow, ncol in (D.U, row + 1, col), (D.D, row - 1, col), (D.L, row, col + 1), (D.R, row, col - 1):
                nrowcol = nrow, ncol
                if chart[nrow][ncol] >= 1 and nrowcol not in curr_path:
                    intersection.append(nrowcol)
            at_intersect = len(intersection) >= 2
            if at_intersect:
                graph[start_path] = ((row, col), len(curr_path) - 1)  # From intersection to intersection
            for nrow, ncol in intersection:
                # pp(curr_path)
                # print(at_intersect)
                # breakpoint()
                if at_intersect:
                    if (row, col) not in graph:
                        next_state.append(((nrow, ncol), {(nrow, ncol), (row, col)}, (row, col)))
                else:
                    ncurr_path = curr_path.copy()
                    ncurr_path.add((nrow, ncol))
                    next_state.append(((nrow, ncol), ncurr_path, start_path))
            intersection.clear()
        current_state.clear()
        current_state.extend(next_state)
    return graph


# for i in chart:
#     print("".join(map(str, i)))
#     print("".join(map(str, i)))
