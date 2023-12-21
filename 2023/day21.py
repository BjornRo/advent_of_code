from dataclasses import dataclass
from heapq import heappop, heappush

Row = int
Col = int
Coords = tuple[Row, Col]


@dataclass
class Queue:
    q: list[Coords]  # = field(default_factory=list)

    def push(self, item: Coords) -> None:
        heappush(self.q, item)

    def pop(self) -> Coords:
        return heappop(self.q)

    def replace(self, list: list[Coords]):
        self.q *= 0
        self.q.extend(list)


with open("in/d21.txt") as f:
    _p = [0]  # padding
    _g = zip(*(_p + [1 if c == "." else 2 if c == "S" else 0 for c in x.strip()] + _p for x in f))
    chart: tuple[tuple[int, ...], ...] = tuple(zip(*(_p + list(y) + _p for y in _g)))


def find_nodes(graph: tuple[tuple[int, ...], ...], steps: int):
    start: Coords = next(((i, j) for i, r in enumerate(graph) for j, s in enumerate(r) if s == 2))
    visited = {start: 0}
    current_epoch = Queue([start])
    next_epoch = Queue([])
    for s in range(1, steps + 1):
        while current_epoch.q:
            x, y = current_epoch.pop()
            for new_xy in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
                if graph[new_xy[0]][new_xy[1]] and new_xy not in visited:
                    visited[new_xy] = s
                    next_epoch.push(new_xy)
        current_epoch.replace(next_epoch.q)
        next_epoch.q *= 0
    return visited


# zeros = [[0] * len(chart[0]) for _ in range(len(chart))]
# for (_row, _col), _ in find_nodes(chart).items():
#     zeros[_row][_col] = 1

# for n in find_nodes(chart).items():
#     print(n)

print(sum(1 for x, y in find_nodes(chart, 64).items() if y % 2 == 0))
