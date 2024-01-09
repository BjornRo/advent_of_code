from time import perf_counter as time_it

start_it = time_it()

plan: list[tuple[str, int, str]]
with open("in/d18.txt") as f:
    plan = [(dir, int(steps), color[1:-1]) for dir, steps, color in (x.strip().split() for x in f if x.strip())]

path: list[tuple[int, int]] = []
row = col = 0
for dir, steps, _ in plan:
    for _ in range(1, steps + 1):
        match dir:
            case "U":
                row -= 1
            case "D":
                row += 1
            case "L":
                col -= 1
            case "R":
                col += 1
        path.append((row, col))


def find_interior(coordinates: list[tuple[int, int]]):
    (R_OFFSET, MAX_ROWS), (C_OFFSET, MAX_COLS) = [
        ((abs(min(rows)), max(rows) + 1), (abs(min(cols)), max(cols) + 1)) for rows, cols in [list(zip(*coordinates))]
    ][0]
    zeros = [[0 for _ in range(MAX_COLS + C_OFFSET)] for _ in range(MAX_ROWS + R_OFFSET)]
    for _row, _col in coordinates:
        zeros[_row + R_OFFSET][_col + C_OFFSET] = 1
    stack: list[tuple[int, int]] = []
    for i, row in enumerate(zeros):
        if not sum(row) % 2:
            j = row.index(1) + 1
            if not zeros[i][j]:
                zeros[i][j] = 1
                stack.append((i, j))
                break
        if stack:
            break
    visited = {stack[0]}
    while stack:
        x, y = stack.pop()
        for row, col in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
            if (row, col) in visited or zeros[row][col]:  # If matrix == 1, continue
                continue
            zeros[row][col] = 1
            visited.add((row, col))
            stack.append((row, col))
    return zeros


print("Part 1:", sum(c for r in find_interior(path) for c in r))

"""
Part 2
"""

polygons: list[tuple[int, int]] = []
total = row = col = 0
for dir, steps in ((int(color[-1]), int(color[1:-1], 16)) for _, _, color in plan):
    match dir:
        case 0:
            col += steps
        case 1:
            row += steps
        case 2:
            col -= steps
        case 3:
            row -= steps
    total += steps
    polygons.append((row, col))


def surveyors(vertices: list[tuple[int, int]], initial_area=0) -> float:
    n, area = len(vertices), 0.0
    for i in range(n):
        j = (i + 1) % n
        area += vertices[i][0] * vertices[j][1] - vertices[j][0] * vertices[i][1]
    return (abs(area) + initial_area) / 2.0


print("Part 2:", int(surveyors(polygons, total) + 1))
print("Finished in:", round(time_it() - start_it, 4), "secs")
