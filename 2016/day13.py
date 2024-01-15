from collections import deque

Row, Col, Steps = [int] * 3
State = tuple[Row, Col, Steps]

with open("in/d13.txt") as f:
    NUMMER = int(f.read().rstrip())
END = 39, 31  # Reversed due to indexing of matrix
min_steps, visited, distinct = 1 << 32, set(), 0
queue: deque[State] = deque([(1, 1, 0)])
while queue:
    row, col, steps = queue.popleft()
    if (row, col) == END:
        if steps < min_steps:
            min_steps = steps
        continue
    if min_steps <= steps or (k := (row, col)) in visited:
        continue
    visited.add(k)
    if steps <= 50:
        distinct += 1
    for r, c in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
        if r >= 0 and c >= 0 and bin((c * c) + (3 * c) + (2 * c * r) + r + r**2 + NUMMER)[2:].count("1") % 2 == 0:
            queue.append((r, c, steps + 1))
print("Part 1:", min_steps)
print("Part 2:", distinct)
