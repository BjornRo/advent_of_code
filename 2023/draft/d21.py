def expand_chart(graph):
    start_row, start_col = next(((i, j) for i, r in enumerate(graph[1:-1]) for j, s in enumerate(r[1:-1]) if s == 2))
    start_row += len(graph[1:-1])
    start_col += len(graph[1:-1][0][1:-1])
    pad = [0]
    exp_chart = [pad + [int(c >= 1) for c in r[1:-1] * 3] + pad for r in graph[1:-1] * 3]
    exp_chart = [pad * len(exp_chart[0])] + exp_chart + [pad * len(exp_chart[0])]
    exp_chart[start_row + 1][start_col + 1] = 2
    return exp_chart


def find_nodes(graph: tuple[tuple[int, ...], ...] | list[list[int]], steps: int):
    start = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
    visited = {start: 0}
    current_epoch = [start]  # Since each epoch only moves certain steps
    next_epoch = []  # stack/queue does not matter for this type of bfs.
    for s in range(1, steps + 1):
        while current_epoch:
            x, y = current_epoch.pop()
            for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
                if graph[new_xy[0]][new_xy[1]] >= 1 and new_xy not in visited:
                    visited[new_xy] = s
                    next_epoch.append(new_xy)
        current_epoch *= 0
        current_epoch.extend(next_epoch)
        next_epoch *= 0
    return visited


# e = lambda steps: sum(1 for y in find_nodex(chart, steps).values() if y % 2 == 0)

# print("Part 1:", e(64))


# def fn(graph: tuple[tuple[int, ...], ...] | list[list[int]]):
#     start: Coords = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
#     visited = {start: 0}
#     current_epoch = Queue([start])
#     next_epoch = Queue([])
#     s = 0
#     while True:
#         s += 1
#         while current_epoch.q:
#             x, y = current_epoch.pop()
#             for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
#                 if graph[new_xy[0]][new_xy[1]] >= 1 and new_xy not in visited:
#                     visited[new_xy] = s
#                     next_epoch.push(new_xy)
#         current_epoch.replace(next_epoch.q)
#         next_epoch.q *= 0
#         if not current_epoch.q:
#             break
#     return visited


def find_nodex(graph: tuple[tuple[int, ...], ...] | list[list[int]], steps: int):
    start = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
    mrow, mcol = len(graph) - 1, len(graph[0]) - 1
    visited = {(start, *[0] * 2): 0}
    current_epoch = [(start, 0, 0)]
    next_epoch = []
    for s in range(1, steps + 1):
        while current_epoch:
            (x, y), dimx, dimy = current_epoch.pop()
            for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
                if not graph[new_xy[0]][new_xy[1]]:
                    continue  # wall
                dimxx, dimyy = dimx, dimy
                if graph[new_xy[0]][new_xy[1]] == -1:
                    xx, yy = new_xy
                    if xx == 0:
                        xx = mrow - 1
                        dimxx -= 1
                    elif xx == mrow:
                        xx = 1
                        dimxx += 1
                    elif yy == 0:
                        yy = mcol - 1
                        dimyy -= 1
                    elif yy == mcol:
                        yy = 1
                        dimyy += 1
                    new_xy = (xx, yy)
                if (new_xy, dimxx, dimyy) not in visited:
                    visited[(new_xy, dimxx, dimyy)] = s
                    next_epoch.append((new_xy, dimxx, dimyy))
        current_epoch.extend(next_epoch)
        next_epoch *= 0
    return visited



def beyond_infinity(graph: tuple[tuple[int, ...], ...], start: tuple[int, int], steps: int):  # Typechecker: *[0]*2..
    max_row, max_col, start_node = len(graph) - 1, len(graph[0]) - 1, (*start, *[0] * 2)  # Row,Col,NDimRow,NDimCol
    current_epoch, next_epoch, visited = [start_node], [], {start_node: 1}
    for step in range(1, steps + 1):
        while current_epoch:
            row, col, dimr, dimc = current_epoch.pop()
            for nrow, ncol in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
                if tile := graph[nrow][ncol]:
                    dimrr, dimcc = dimr, dimc
                    if tile == -1:  # New dimension to explore
                        if nrow == 0:
                            nrow = max_row - 1
                            dimrr -= 1
                        elif nrow == max_row:
                            nrow = 1
                            dimrr += 1
                        elif ncol == 0:
                            ncol = max_col - 1
                            dimcc -= 1
                        elif ncol == max_col:
                            ncol = 1
                            dimcc += 1
                    if (nrow, ncol, dimrr, dimcc) not in visited:
                        visited[(nrow, ncol, dimrr, dimcc)] = step % 2 == 0
                        next_epoch.append((nrow, ncol, dimrr, dimcc))
        current_epoch.extend(next_epoch)
        next_epoch *= 0
    return visited
