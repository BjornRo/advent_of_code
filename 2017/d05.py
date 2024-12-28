with open("in/d05.txt") as f:
    data = tuple(int(x.strip()) for x in f)


def solver(xs: list[int], func=lambda _: 1) -> int:
    steps = 0
    i = 0
    while 0 <= i < len(xs):
        jump = xs[i]
        xs[i] += func(jump)
        i += jump
        steps += 1
    return steps


print(f"Part 1: {solver(list(data))}")
print(f"Part 2: {solver(list(data), lambda x: -1 if x >= 3 else 1)}")
