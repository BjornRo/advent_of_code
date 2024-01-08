from heapq import heappop, heappush

with open("in/d17.txt") as f:
    _p = lambda x: (0, *x, 0)  # Padding
    chart = tuple(zip(*(_p(y) for y in zip(*(_p(int(c) for c in x.rstrip()) for x in f)))))


PathSum, Row, Col, Steps, Dir = [int] * 5  #  Up, Down, Left, Right
END, DIRS, State = ((len(chart) - 2, len(chart[0]) - 2)), {0: 1, 1: 0, 2: 3, 3: 2}, tuple[Row, Col, Dir, Steps]


def crucial(max_steps: int, part2: bool):
    queue: list[tuple[PathSum, State]] = [(0, (1, 1, 3, 1)), (0, (1, 1, 1, 1))]
    visited = set()
    while queue:
        path_sum, (row, col, dir, steps) = heappop(queue)
        if (row, col) == END:
            if part2 and steps < 4:
                continue
            return path_sum
        if (k := (row, col, dir, steps)) not in visited:
            visited.add(k)
            for i in DIRS:
                if i != DIRS[dir]:  # No 180s
                    _row, _col = row, col
                    match i:
                        case 0:
                            _row -= 1
                        case 1:
                            _row += 1
                        case 2:
                            _col -= 1
                        case 3:
                            _col += 1
                    if index_value := chart[_row][_col]:
                        if part2 and i != dir and steps < 4:
                            continue
                        if i == dir:
                            if steps >= max_steps:
                                continue
                            _steps = steps + 1
                        else:
                            _steps = 1
                        heappush(queue, (path_sum + index_value, (_row, _col, i, _steps)))


print("Part 1:", crucial(max_steps=3, part2=False))
print("Part 2:", crucial(max_steps=10, part2=True))
