position, current_turn = complex(0, 0), complex(-1, 0)  # facing north
visited, part2 = {position}, None
with open("in/d1.txt") as f:
    for r_turn, steps in ((y[0] == "R", int(y[1:])) for y in (x.strip() for x in f.read().split(","))):
        current_turn *= -1j if r_turn else 1j
        if part2 is not None:
            position += current_turn * steps
            continue
        for _ in range(steps):
            position += current_turn
            if position in visited and part2 is None:
                part2 = position
                continue
            visited.add(position)

assert isinstance(part2, complex)
complex_sum = lambda x: sum(map(abs, map(int, (x.real, x.imag))))
print("Part 1:", complex_sum(position))
print("Part 2:", complex_sum(part2))
