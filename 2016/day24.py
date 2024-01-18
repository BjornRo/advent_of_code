from collections import defaultdict, deque


def num_theory(vent: tuple[tuple[int, ...], ...], number: int, start: tuple[int, int]):
    visited = set()  # Position, Steps
    queue: deque[tuple[int, int, int]] = deque([(*start, 0)])
    min_steps = 1 << 32
    while queue:
        row, col, steps = queue.popleft()
        if vent[row][col] == number:
            if steps < min_steps:
                min_steps = steps
            continue
        if (k := (row, col)) in visited or steps >= min_steps:
            continue
        visited.add(k)
        for r, c in (row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1):
            if vent[r][c]:
                queue.append((r, c, steps + 1))
    return min_steps


def cartographer(chart: dict[int, dict[int, int]], part2: bool):
    queue: deque[tuple[int, set[int], int]] = deque([(0, {0}, 0)])  # Pos, Visited, Steps
    min_steps, end = 1 << 32, {*chart.keys()}
    while queue:
        pos, visited, steps = queue.popleft()
        if visited == end:
            if part2:
                steps += chart[pos][0]
            if steps < min_steps:
                min_steps = steps
            continue
        for next_pos, next_step in chart[pos].items():
            if next_pos not in visited:
                queue.append((next_pos, {*visited, next_pos}, steps + next_step))
    return min_steps


with open("in/d24.txt") as f:
    vent = tuple(tuple("#.01234567".index(c) for c in x.rstrip()) for x in f)
graph: dict[int, dict[int, int]] = defaultdict(dict)
for i, s in dict(sorted((vent[k][l], (k, l)) for k, r in enumerate(vent) for l, c in enumerate(r) if c >= 2)).items():
    for j in range(2, 10):
        if i != j:
            graph[i - 2][j - 2] = num_theory(vent, j, s)

print("Part 1:", cartographer(graph, False))
print("Part 2:", cartographer(graph, True))
