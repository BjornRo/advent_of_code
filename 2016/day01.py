with open("in/d1.txt") as f:
    maze = [(y[0], int(y[1:])) for y in (x.strip() for x in f.read().split(","))]




maze = [(y[0], int(y[1:])) for y in (x.strip() for x in "R8, R4, R4, R8".split(","))]
position = complex(0, 0)
visited = [(int(position.real), int(position.imag))]

for turn, steps in maze:
    position *= 1j if turn == "R" else -1j
    for _ in range(steps):
        position += 1
    visited.append(position)
    print(position)
    breakpoint()
    converted = (int(position.real), int(position.imag))
    print(position)
    if converted in visited:
        print(converted)
    visited.append((int(position.real), int(position.imag)))
print(abs(int(position.real)) + abs(int(position.imag)))
