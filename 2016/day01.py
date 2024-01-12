with open("in/d1.txt") as f:
    maze = [(y[0] == "R", int(y[1:])) for y in (x.strip() for x in f.read().split(","))]

position, current_turn, part2 = complex(0, 0), complex(-1, 0), None
visited = {position}
for r_turn, steps in maze:
    current_turn *= -1j if r_turn else 1j
    if part2 is None:
        for _ in range(steps):
            position += current_turn
            if position in visited and part2 is None:
                part2 = position
                continue
            visited.add(position)
    else:
        position += current_turn * steps

assert isinstance(part2, complex)
complex_sum = lambda x: sum(map(abs, map(int, (x.real, x.imag))))
print("Part 1:", complex_sum(position))
print("Part 2:", complex_sum(part2))
