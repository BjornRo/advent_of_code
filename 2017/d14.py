from itertools import batched

with open("in/d14.txt") as f:
    data = f.read().rstrip()


def knot_hash(data: str) -> str:
    circ_list = list(range(256))
    skip_size = 0
    curr_position = 0
    for _ in range(64):
        for i in list(data.encode()) + [17, 31, 73, 47, 23]:
            for j in range(i // 2):
                k = (curr_position + j) % len(circ_list)
                l = (curr_position + i - j - 1) % len(circ_list)
                circ_list[k], circ_list[l] = circ_list[l], circ_list[k]
            curr_position = (curr_position + i + skip_size) % len(circ_list)
            skip_size += 1
    dense_hash = []
    for i in batched(circ_list, 16):
        dhash = 0
        for j in i:
            dhash ^= j
        dense_hash.append(dhash)
    return bytes(dense_hash).hex()


def part2(matrix: list[list[int]]):
    DIM = 128
    in_bound = lambda row, col: 0 <= row < DIM and 0 <= col < DIM

    regions = 0
    for i in range(DIM):
        for j in range(DIM):
            if not matrix[i][j]:
                continue
            regions += 1
            stack = [(i, j)]
            while stack:
                row, col = stack.pop()
                if not matrix[row][col]:
                    continue
                matrix[row][col] = 0

                for dr, dc in (1, 0), (0, 1), (-1, 0), (0, -1):
                    nr, nc = row + dr, col + dc
                    if in_bound(nr, nc):
                        stack.append((nr, nc))
    return regions


matrix = [list(map(int, f"{int(knot_hash(f"{data}-{i}"), 16):0128b}")) for i in range(128)]
print(f"Part 1: {sum(sum(x) for x in matrix)}")
print(f"Part 2: {part2(matrix)}")
