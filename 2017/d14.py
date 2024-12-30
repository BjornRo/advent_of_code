from d10 import part2 as knot_hash

with open("in/d14.txt") as f:
    data = f.read().rstrip()

matrix = [list(map(int, f"{int(knot_hash(f"{data}-{i}"), 16):0128b}")) for i in range(128)]


def part1(matrix: list[list[int]]):
    return sum(sum(x) for x in matrix)


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


print(f"Part 1: {part1(matrix)}")
print(f"Part 2: {part2(matrix)}")
