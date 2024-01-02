mat, SCALE = [tuple(x.strip()) for x in open("in/d10.txt") if x.strip()], 3
SROW, SCOL = len(mat) * SCALE, len(mat[0]) * SCALE
baseshapes = (((0, 0, 0), (1, 1, 1), (0, 0, 0)), ((0, 1, 0), (0, 1, 1), (0, 0, 0)))  # Shapes: [-, L]
shapes: dict[str, tuple[tuple[int, ...], ...]] = {
    "S": ((0, 1, 0), (1, 2, 1), (0, 1, 0)),
    ".": ((0,) * SCALE,) * SCALE,
    "-": baseshapes[0],
    "L": baseshapes[1],
    "|": tuple(zip(*baseshapes[0])),  # Transpose
    "7": tuple(zip(*baseshapes[1])),  # Transpose
    "F": baseshapes[1][::-1],  # Vertical flip
    "J": tuple(x[::-1] for x in baseshapes[1]),  # Horizontal flip
}


def find_nodes(graph: list[list[int]] | list[list[bool]], start_node: tuple[int, int], wall=0) -> list[list[bool]]:
    visited, stack = [[False] * SCOL for _ in range(SROW)], [start_node]
    while stack:
        row, col = stack.pop()
        for r, c in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
            if graph[r][c] != wall and not visited[r][c]:
                visited[r][c] = True
                stack.append((r, c))
    return visited


def find_start(matrix: list[list[bool]] | list[list[int]], targ_val: int, offset=0) -> tuple[int, int]:
    return next((i + offset, j + offset) for i, r in enumerate(matrix) for j, c in enumerate(r) if c == targ_val)


empty_mat = [[0] * SCOL for _ in range(SROW)]
for I in range(0, SROW, SCALE):
    for Ii in range(0, SCOL, SCALE):
        for II in range(SCALE):
            for I_ in range(SCALE):
                empty_mat[I + II][Ii + I_] = shapes[mat[I // SCALE][Ii // SCALE]][II][I_]

counter = lambda matrix: sum(matrix[i][j] for i in range(1, SROW, SCALE) for j in range(1, SCOL, SCALE))
strike = find_nodes(empty_mat, start_node=find_start(empty_mat, 2), wall=0)
print("Part 1:", counter(strike) // 2)
print("Part 2:", counter(find_nodes(strike, start_node=find_start(strike, 1, 1), wall=1)))
