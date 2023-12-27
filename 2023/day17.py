from enum import IntEnum, auto
from heapq import heappop, heappush

with open("in/d17.txt") as f:
    p = [0]  # padding
    raw_mat = tuple(zip(*(p + list(y) + p for y in zip(*(p + [int(c) for c in x.rstrip()] + p for x in f)))))


class Dir(IntEnum):
    U = auto()
    D = auto()
    L = auto()
    R = auto()


PathSum = Row = Col = Steps = int
END, State = ((len(raw_mat) - 2, len(raw_mat[0]) - 2)), tuple[Row, Col, Dir, Steps]


def crucial(max_steps: int, part2: bool):
    queue: list[tuple[PathSum, State]] = [(0, (1, 1, Dir.R, 1)), (0, (1, 1, Dir.D, 1))]
    visited = set()
    while queue:
        path_sum, (row, col, dir, steps) = heappop(queue)
        if (row, col) == END:
            if part2 and steps < 4:
                continue
            return path_sum
        if (k := (row, col, dir, steps)) not in visited:
            visited.add(k)
            for i in Dir:
                if i != {Dir.U: Dir.D, Dir.D: Dir.U, Dir.L: Dir.R, Dir.R: Dir.L}[dir]:
                    _row, _col = row, col
                    match i:
                        case Dir.U:
                            _row -= 1
                        case Dir.D:
                            _row += 1
                        case Dir.L:
                            _col -= 1
                        case Dir.R:
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
