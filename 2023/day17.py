from enum import IntEnum, auto
from heapq import heappop, heappush

with open("in/d17.txt") as f:
    p = [0]  # padding
    raw_mat = tuple(zip(*(p + list(y) + p for y in zip(*(p + [int(c) for c in x.rstrip()] + p for x in f)))))


class Dir(IntEnum):
    UP = auto()
    DOWN = auto()
    LEFT = auto()
    RIGHT = auto()


END = (len(raw_mat) - 2, len(raw_mat[0]) - 2)
PathSum = Row = Col = Steps = int
State = tuple[Row, Col, Dir, Steps]


def crucial(max_steps: int, part2: bool):
    visited = set()
    queue: list[tuple[PathSum, State]] = []
    start: list[State] = [(1, 1, Dir.RIGHT, 1), (1, 1, Dir.DOWN, 1)]
    for s in start:
        heappush(queue, (0, s))

    while queue:
        path_sum, (row, col, dir, steps) = heappop(queue)

        if (row, col) == END:
            if part2 and steps < 4:
                continue
            return path_sum

        if (row, col, dir, steps) in visited:
            continue
        visited.add((row, col, dir, steps))

        for i in Dir:
            if i == {Dir.UP: Dir.DOWN, Dir.DOWN: Dir.UP, Dir.LEFT: Dir.RIGHT, Dir.RIGHT: Dir.LEFT}[dir]:
                continue
            _row, _col = row, col
            match i:
                case Dir.UP:
                    _row -= 1
                case Dir.DOWN:
                    _row += 1
                case Dir.LEFT:
                    _col -= 1
                case Dir.RIGHT:
                    _col += 1
            if index_value := raw_mat[_row][_col]:
                _steps = 1
                if i == dir:
                    if steps >= max_steps:
                        continue
                    _steps = steps + 1
                elif part2 and i != dir and steps < 4:
                    continue
                heappush(queue, (path_sum + index_value, (_row, _col, i, _steps)))


print("Part 1:", crucial(max_steps=3, part2=False))
print("Part 2:", crucial(max_steps=10, part2=True))
