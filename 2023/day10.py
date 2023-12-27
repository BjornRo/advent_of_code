mat = [tuple(x.strip()) for x in open("in/d10.txt") if x.strip()]
ROW, COL, SCALE = len(mat), len(mat[0]), 3
SROW, SCOL = ROW * SCALE, COL * SCALE
baseshapes = [[[0, 0, 0], [1, 1, 1], [0, 0, 0]], [[0, 1, 0], [0, 1, 1], [0, 0, 0]]]  # Shapes: [-, L]
shapes = {  # Shape-Box will be 1 when downscaled again
    "S": [[0, 1, 0], [1, 2, 1], [0, 1, 0]],
    ".": [[0] * SCALE] * SCALE,
    "-": baseshapes[0],
    "L": baseshapes[1],
    "|": list(zip(*baseshapes[0])),  # Transpose
    "7": list(zip(*baseshapes[1])),  # Transpose
    "F": baseshapes[1][::-1],  # Vertical flip
    "J": [x[::-1] for x in baseshapes[1]],  # Horizontal flip
}

new_mat = [[0] * SCOL for _ in range(SROW)]
for i in range(0, SROW, SCALE):
    for j in range(0, SCOL, SCALE):
        for k in range(SCALE):
            for l in range(SCALE):
                new_mat[i + k][j + l] = shapes[mat[i // SCALE][j // SCALE]][k][l]


def find_nodes(graph: list[list[int]] | list[list[bool]], start_node: tuple[int, int], wall=0) -> list[list[bool]]:
    (_r, _c), visited, stack = (SROW, SCOL), [[False] * SCOL for _ in range(SROW)], [start_node]
    while stack:
        x, y = stack.pop()
        for r, c in (min(x + 1, _r), y), (max(x - 1, 0), y), (x, min(y + 1, _c)), (x, max(y - 1, 0)):
            if graph[r][c] != wall and not visited[r][c]:
                visited[r][c] = True
                stack.append((r, c))
    return visited


def find_start(matrix: list[list[bool]] | list[list[int]], target_val: int, offset=0):
    for i, r in enumerate(matrix):
        for j, c in enumerate(r):
            if c == target_val:
                return i + offset, j + offset
    assert False


def counter(matrix: list[list[bool]], strategy=lambda x: -(-(x / SCALE**2) // 1)):
    steps = square = 0
    for i in range(0, SROW, SCALE):
        for j in range(0, SCOL, SCALE):
            for k in range(SCALE):
                for l in range(SCALE):
                    square += matrix[i + k][j + l]
            steps, square = steps + strategy(square), 0
    return steps


path = find_nodes(new_mat, start_node=find_start(new_mat, 2))
insider = find_nodes(path, start_node=find_start(path, 1, 1), wall=1)
print("Part 1:", int(counter(path) // 2))
print("Part 2:", int(counter(insider, lambda x: (x / SCALE**2) // 1)))
