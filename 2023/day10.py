import numpy as np

mat = [tuple(x.strip()) for x in open("d10.txt") if x.strip()]
ROW, COL, SCALE = len(mat), len(mat[0]), 3
baseshapes = [[[0, 0, 0], [1, 1, 1], [0, 0, 0]], [[0, 1, 0], [0, 1, 1], [0, 0, 0]]] # Shapes: [-, L]
shapes = {  # Shape-Box will be 1 when downscaled again
    "S": [[0, 1, 0], [1, 2, 1], [0, 1, 0]],
    ".": [[0] * SCALE] * SCALE,
    "-": baseshapes[0],
    "L": baseshapes[1],
    "|": list(zip(*baseshapes[0])), # Transpose
    "7": list(zip(*baseshapes[1])), # Transpose
    "F": baseshapes[1][::-1], # Vertical flip
    "J": [x[::-1] for x in baseshapes[1]], # Horizontal flip
}

new_mat = np.zeros((ROW * SCALE, COL * SCALE)) # Upscale by SCALE
for i in range(ROW):
    for j in range(COL):
        new_mat[i * SCALE : (i + 1) * SCALE, j * SCALE : (j + 1) * SCALE] = shapes[mat[i][j]]

def find_nodes(graph: np.ndarray, start_node: tuple[int, int]) -> np.ndarray:
    (_r, _c), visited, stack = (x - 1 for x in graph.shape), np.zeros_like(graph, dtype=bool), [start_node]
    while stack:
        x, y = stack.pop()
        for new_node in ((min(x + 1, _r), y), (max(x - 1, 0), y), (x, min(y + 1, _c)), (x, max(y - 1, 0))):
            if graph[*new_node] and not visited[*new_node]:
                visited[*new_node] = True
                stack.append(new_node)
    return visited

downsampler = lambda p, h: h(p.reshape((ROW, SCALE, COL, SCALE)).mean(axis=(1, 3))).astype(bool)
path = find_nodes(new_mat, start_node=next(zip(*np.where(new_mat == 2))))
print("Part 1:", np.sum(downsampler(path, np.ceil)) // 2) # Inverse to reuse find_nodes to "fill" the rest.
print("Part 2:", np.sum(downsampler(~(find_nodes(~path, start_node=(0, 0)) | path), np.floor)))
