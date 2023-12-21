import math
from dataclasses import dataclass
from heapq import heappop, heappush

with open("in/d21.txt") as f:
    _p = [-1]  # padding
    _g = zip(*(_p + [1 if c == "." else 2 if c == "S" else 0 for c in x.strip()] + _p for x in f))
    chart: tuple[tuple[int, ...], ...] = tuple(zip(*(_p + list(y) + _p for y in _g)))


Row = int
Col = int
Coords = tuple[Row, Col]


@dataclass
class Queue:
    q: list  # = field(default_factory=list)

    def push(self, item) -> None:
        heappush(self.q, item)

    def pop(self) -> tuple:
        return heappop(self.q)

    def replace(self, list: list):
        self.q *= 0
        self.q.extend(list)


def find_nodes(graph: tuple[tuple[int, ...], ...] | list[list[int]], steps: int):
    start: Coords = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
    visited = {start: 0}
    current_epoch = Queue([start])
    next_epoch = Queue([])
    for s in range(1, steps + 1):
        while current_epoch.q:
            x, y = current_epoch.pop()
            for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
                if graph[new_xy[0]][new_xy[1]] >= 1 and new_xy not in visited:
                    visited[new_xy] = s
                    next_epoch.push(new_xy)
        current_epoch.replace(next_epoch.q)
        next_epoch.q *= 0
    return visited


def expand_chart(graph):
    start_row, start_col = next(((i, j) for i, r in enumerate(graph[1:-1]) for j, s in enumerate(r[1:-1]) if s == 2))
    start_row += len(graph[1:-1])
    start_col += len(graph[1:-1][0][1:-1])
    pad = [0]
    exp_chart = [pad + [int(c >= 1) for c in r[1:-1] * 3] + pad for r in graph[1:-1] * 3]
    exp_chart = [pad * len(exp_chart[0])] + exp_chart + [pad * len(exp_chart[0])]
    exp_chart[start_row + 1][start_col + 1] = 2
    return exp_chart


def find_nodex(graph: tuple[tuple[int, ...], ...] | list[list[int]], steps: int):
    start: Coords = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
    mrow, mcol = len(graph) - 1, len(graph[0]) - 1
    visited = {(start, 0, 0): 0}
    current_epoch = Queue([(start, 0, 0)])
    next_epoch = Queue([])
    for s in range(1, steps + 1):
        while current_epoch.q:
            (x, y), dimx, dimy = current_epoch.pop()
            for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
                dimxx, dimyy = dimx, dimy
                if not graph[new_xy[0]][new_xy[1]]:
                    continue  # wall
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
                    next_epoch.push((new_xy, dimxx, dimyy))
        current_epoch.replace(next_epoch.q)
        next_epoch.q *= 0
    return visited


def fn(graph: tuple[tuple[int, ...], ...] | list[list[int]]):
    start: Coords = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
    visited = {start: 0}
    current_epoch = Queue([start])
    next_epoch = Queue([])
    s = 0
    while True:
        s += 1
        while current_epoch.q:
            x, y = current_epoch.pop()
            for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
                if graph[new_xy[0]][new_xy[1]] >= 1 and new_xy not in visited:
                    visited[new_xy] = s
                    next_epoch.push(new_xy)
        current_epoch.replace(next_epoch.q)
        next_epoch.q *= 0
        if not current_epoch.q:
            break
    return visited


def e(steps):
    return sum(1 for y in find_nodex(chart, steps).values() if y % 2 == 0)


print("Part 1:", e(64))
