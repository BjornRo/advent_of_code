from time import time as time_it

start_it = time_it()


def rock_it(matrix: tuple[tuple[int, ...], ...]) -> tuple[tuple[int, ...], ...]:
    new_matrix, stack, waiting_rocks = [], [], []
    row_len = len(matrix[0]) - 1
    for row in matrix:
        for i in range(row_len, -1, -1):
            c = row[i]
            if c == 2:
                waiting_rocks.append(c)
                continue
            if not c:
                stack.extend(waiting_rocks)
                waiting_rocks.clear()
            stack.append(c)
        stack.extend(waiting_rocks)
        new_matrix.append(tuple(stack))
        stack.clear()
        waiting_rocks.clear()
    return tuple(new_matrix)


def count_it(matrix: tuple[tuple[int, ...], ...]) -> int:
    total = 0
    for row in matrix:
        for i, j in enumerate(row, 1):
            if j == 2:
                total += i
    return total


trans_it = lambda x: tuple(zip(*x))


def recycle_it(matrix: tuple[tuple[int, ...], ...]) -> int:
    index, cycling = 0, {}
    while True:
        index += 1
        matrix = trans_it(rock_it(trans_it(rock_it(trans_it(rock_it(trans_it(rock_it(matrix))))))))
        if matrix in cycling and (1_000_000_000 - index) % (index - cycling[matrix]) == 0:
            return count_it(row[::-1] for row in matrix)  # type: ignore - Generators are ok
        cycling[matrix] = index


with open("in/d14.txt") as f:
    raw_matrix = trans_it((0 if c == "#" else 1 if c == "." else 2 for c in x.rstrip()) for x in f)

print("Part 1:", count_it(rock_it(raw_matrix)))
print("Part 2:", recycle_it(raw_matrix))
print("Finished in:", round(time_it() - start_it, 4), "secs")
