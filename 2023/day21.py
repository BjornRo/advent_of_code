from collections import deque

with open("in/d21.txt") as f:
    _p = [-1]  # padding
    _g = zip(*(_p + [1 if c == "." else 2 if c == "S" else 0 for c in x.strip()] + _p for x in f))
    chart: tuple[tuple[int, ...], ...] = tuple(zip(*(_p + list(y) + _p for y in _g)))

Row, Col, DimRow, DimCol = [int] * 4
Key = tuple[Row, Col, DimRow, DimCol]


def beyond_infinity(graph: tuple[tuple[int, ...], ...], start: Key, ssteps: int) -> set[Key]:
    max_grid, less_max_grid = len(graph) - 1, len(graph) - 2
    queue, visited = deque([(*start, ssteps)]), {start}
    gardens: set[Key] = set()
    while queue:
        row, col, dimr, dimc, steps = queue.popleft()
        if steps % 2 == 0:
            gardens.add((row, col, dimr, dimc))
        if not steps:
            continue
        for nrow, ncol in (row + 1, col), (row - 1, col), (row, col + 1), (row, col - 1):
            if tile := graph[nrow][ncol]:
                dimrr, dimcc = dimr, dimc
                if tile == -1:  # New dimension to explore
                    if nrow == 0:
                        nrow = less_max_grid
                        dimrr -= 1
                    elif nrow == max_grid:
                        nrow = 1
                        dimrr += 1
                    elif ncol == 0:
                        ncol = less_max_grid
                        dimcc -= 1
                    elif ncol == max_grid:
                        ncol = 1
                        dimcc += 1
                if (k := (nrow, ncol, dimrr, dimcc)) not in visited:
                    visited.add(k)
                    queue.append((*k, steps - 1))
    return gardens


partial_inf = lambda steps: beyond_infinity(chart, (66, 66, 0, 0), steps)
print("Part 1:", len(partial_inf(64)))


def gardens_in_dim(gardens: set[Key], dim_row: int, dim_col: int) -> int:
    return sum(1 for (_, _, dr, dc) in gardens if dr == dim_row and dc == dim_col)


grid_size = len(chart) - 2  # 131
n_grids = (26501365 - 65) // grid_size  # 202300
gardens = partial_inf(65 + grid_size * 2)

evens = (gardens_in_dim(gardens, 0, 0)) * (n_grids - 1) ** 2
odds = (gardens_in_dim(gardens, 1, 0)) * n_grids**2
corners = sum(gardens_in_dim(gardens, r, c) for r, c in ((-2, 0), (0, 2), (2, 0), (0, -2)))
even_border = sum((n_grids - 1) * gardens_in_dim(gardens, r, c) for r, c in ((-1, 1), (1, 1), (1, -1), (-1, -1)))
odd_border = sum(n_grids * gardens_in_dim(gardens, r, c) for r, c in ((-2, 1), (1, 2), (1, -2), (-2, -1)))
print("Part 2:", evens + odds + corners + even_border + odd_border)

"""
See charts in draft folder.
My infinity function stores dimensions, which makes it trivial to count the odd/evens(parity),
the partial diamonds etc... The grid is 131. And we start in the middle. So 65 steps to get
out from the grid, then 2 full grids (131*2) to get all cases

All values have (upper, down, left, right) partial triangles from evens.
What is left is the partial even/odds from the borders.
n = 2:
    even: 1 (1*1) (n-1)
    odd: 4 (2*2) (n^2)
    ne border:
        even: 1 (n-1)
        odd: 2 (n)
    se border:
        even: 1 (n-1)
        odd: 2 (n)
    sw border:
        even: 1 (n-1)
        odd: 2 (n)
    nw border:
        even: 1 (n-1)
        odd: 2 (n)
n = 4
    even: 9 (3*3) (n-1)
    odd: 16 (4*4) (n^2)
    ne border:
        even: 3 (n-1)
        odd: 4 (n)
    se border:
        even: 3 (n-1)
        odd: 4 (n)
    sw border:
        even: 3 (n-1)
        odd: 4 (n)
    nw border:
        even: 3 (n-1)
        odd: 4 (n)
n = 6
    even: 25 (5*5) (n-1)
    odd: 36 (6*6) (n^2)
    ne border:
        even: 5 (n-1)
        odd: 6 (n)
    se border:
        even: 5 (n-1)
        odd: 6 (n)
    sw border:
        even: 5 (n-1)
        odd: 6 (n)
    nw border:
        even: 5 (n-1)
        odd: 6 (n)
"""
