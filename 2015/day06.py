grid1, grid2 = [[0] * 1000 for _ in range(1000)], [[0] * 1000 for _ in range(1000)]
with open("in/d6.txt") as f:
    for c, i in (x.rstrip().replace(" through ", ",").rsplit(" ", 1) for x in f):
        row_min, col_min, row_max, col_max = map(int, i.split(","))
        match c:
            case "turn on":
                for r in range(row_min, row_max + 1):
                    for c in range(col_min, col_max + 1):
                        grid1[r][c] = 1
                        grid2[r][c] += 1
            case "turn off":
                for r in range(row_min, row_max + 1):
                    for c in range(col_min, col_max + 1):
                        grid1[r][c] = 0
                        grid2[r][c] = max(0, grid2[r][c] - 1)
            case "toggle":
                for r in range(row_min, row_max + 1):
                    for c in range(col_min, col_max + 1):
                        grid1[r][c] ^= 1
                        grid2[r][c] += 2
print("Part 1:", sum(c for row in grid1 for c in row))
print("Part 2:", sum(c for row in grid2 for c in row))
