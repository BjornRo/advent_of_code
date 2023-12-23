from collections import deque

m = {"0": "R", "1": "D", "2": "L", "3": "U"}
with open("in/e18.txt") as f:
    plan = [(m[color[-2]], int(color[2:-2], 16)) for _, _, color in (x.strip().split() for x in f if x.strip())]

with open("in/d18.txt") as f:
    plan = [(dir, int(steps)) for dir, steps, _ in (x.strip().split() for x in f if x.strip())]


down = 1
for dir, steps in plan:
    match dir:
        case "D":
            down += steps


"""
Först passera halva första delen
BRED = 1
####### -> BRED += 6
#.....# 7 Räkna till 5
###...# 7
..#...# 7
..#...# 7
###.### Här är 7. L Säger BRED -= 2 = 5
#...#.. 5 Räkna till 2
##..### Här är 2. R säger BRED += 2 = 7
.#....# Räkna till 2 = 7
.###### Här är 2. L Säger BRED -= 5+1 = 1
"""

# 7 7 7 7 7 7 5 7 7 7

curr_row = 0
width = 0
dd = [0] * down
for i in range(len(plan) // 2):
    dir, steps = plan[i]
    match dir:
        case "L":
            dd[curr_row] = width
            width -= steps
            curr_row += 1
        case "R":
            width += steps
            dd[curr_row] = width
            curr_row += 1
        case "D":
            for _ in range(steps - 1):
                dd[curr_row] = width
                curr_row += 1
print(dd)

bd = dd.copy()[::-1]
curr_row = 1
diff = width - 1
bd[0] -= diff
for i in range(len(plan) // 2, len(plan)):
    dir, steps = plan[i]
    match dir:
        case "L":
            diff -= steps
            bd[curr_row] -= diff
            curr_row += 1
        case "R":
            bd[curr_row] -= diff
            diff += steps
            curr_row += 1
        case "U":
            for _ in range(steps - 1):
                bd[curr_row] -= diff
                curr_row += 1
bd[-1] -= diff
print(bd)
print(sum(map(lambda x: x-min(bd),bd)))
"""
Nu går vi genom resten av halvan. Nerifrån upp
####### -> BRED += 6, 7 - DIFF
#.....# 7 - DIFF = 0
###...# DIFF += 2 = 7 - DIFF = 7
..#...# 7 - DIFF = 5
..#...# 7 - DIFF = 5
###.### DIFF -= 2 = 5-DIFF = 7
#...#.. UPP två = 5-DIFF = 5
##..### DIFF -= 1 = 0. 7-0 = 7
.#....# Upp två. 7-DIFF = 6
.###### DIFF = 1
U 2
L 1
U 2
R 2
U 3
L 2
U 2

##

R 6
D 5
L 2
D 2
R 2
D 2
L 5

U 2
L 1
U 2
R 2
U 3
L 2
U 2

Först passera halva första delen
BRED = 1
####### -> BRED += 6
#.....# 7 Räkna till 5
###...# 7
..#...# 7
..#...# 7
###.### Här är 5. L Säger BRED -= 2 = 5
#...#.. 5 Räkna till 2
##..### Här är 2. R säger BRED += 2 = 7
.#....# Räkna till 2 = 7
.###### Här är 2. L Säger BRED -= 5+1 = 1

Nu går vi genom resten av halvan. Nerifrån upp
####### -> BRED += 6, 7 - DIFF
#.....# 7 - DIFF = 0
###...# DIFF += 2 = 7 - DIFF = 7
..#...# 7 - DIFF = 5
..#...# 7 - DIFF = 5
###.### DIFF -= 2 = 5-DIFF = 7
#...#.. UPP två = 5-DIFF = 5
##..### DIFF -= 1 = 0. 7-0 = 7
.#....# Upp två. 7-DIFF = 6
.###### DIFF = 1

-> 24, 38

"""


# 47527 - 3842 (path len) -> inside area 43685
# dequeue 9917

"""
(6+1)*(2+1) = 21
5-3 = 2*(6+1) = 14-(2*2) = 10


"""


trench = []
row = col = 0
for dir, steps in plan:
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
        trench.append((row, col))

(R_OFFSET, MAX_ROWS), (C_OFFSET, MAX_COLS) = [
    ((abs(min(rows)), max(rows) + 1), (abs(min(cols)), max(cols) + 1)) for rows, cols in [list(zip(*trench))]
][0]

off_trench = []

zeros = [[0 for _ in range(MAX_COLS + C_OFFSET)] for _ in range(MAX_ROWS + R_OFFSET)]
for _row, _col in trench:
    zeros[_row + R_OFFSET][_col + C_OFFSET] = 1

# with open("m.txt", "wt") as f:
#     for r in zeros:
#         f.write("".join(map(str, r)) + "\n")


def find_interior(matrix: list[list[int]]):
    matrix = [[x for x in row] for row in matrix]  # deepcopy
    queue: list[tuple[int, int]] = []
    for i, row in enumerate(matrix):
        if not sum(row) % 2:
            j = row.index(1) + 1
            if not matrix[i][j]:
                matrix[i][j] = 1
                queue.append((i, j))
                break
        if queue:
            break
    visited = {queue[0]}
    while queue:
        x, y = queue.pop()
        for row, col in (x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1):
            if (row, col) in visited or matrix[row][col]:  # If matrix == 1, continue
                continue
            matrix[row][col] = 1
            visited.add((row, col))
            queue.append((row, col))
    return matrix


print("Part 1:", sum(c for r in find_interior(zeros) for c in r))
