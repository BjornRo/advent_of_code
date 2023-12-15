from time import time as time_it

start_it = time_it()


def rock_it(mat: tuple[tuple[int, ...], ...]) -> tuple[tuple[int, ...], ...]:
    new_matrix = []
    rlen = len(mat[0]) - 1
    for row in mat:
        stack = []
        waiting_rocks = []
        for i in range(rlen, -1, -1):
            c = row[i]
            if c == 2:
                waiting_rocks.append(c)
                continue
            if not c:
                stack.extend(waiting_rocks)
                waiting_rocks.clear()
            stack.append(c)
        stack.extend(waiting_rocks)
        waiting_rocks.clear()
        new_matrix.append(tuple(stack))
    return tuple(new_matrix)


def count_it(mat: tuple[tuple[int, ...], ...]) -> int:
    total = 0
    for row in mat:
        for i, j in enumerate(row, 1):
            if j == 2:
                total += i
    return total


flip_it = lambda x: tuple(r[::-1] for r in x)
spin_it = lambda x: trans_it(rock_it(trans_it(rock_it(trans_it(rock_it(trans_it(rock_it(x))))))))
trans_it = lambda x: tuple(zip(*x))


def recycle_it(mat: tuple[tuple[int, ...], ...]):
    index, cycling = 0, {}
    while True:
        index += 1
        mat = spin_it(mat)
        result = count_it(flip_it(mat))
        if mat in cycling and (1_000_000_000 - index) % (index - cycling[mat]) == 0:
            return result
        cycling[mat] = index


with open("in/14.in") as f:
    raw_mat = trans_it((0 if c == "#" else 1 if c == "." else 2 for c in x.rstrip()) for x in f)

print("Part 1:", count_it(rock_it(raw_mat)))
print("Part 2:", recycle_it(raw_mat))
print("Finished in:", round(time_it() - start_it, 4), "secs")
