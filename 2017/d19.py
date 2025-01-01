with open("in/d19.txt") as f:
    matrix = [x.rstrip("\n\r") for x in f]

coord2elem = lambda c: matrix[int(c.real)][int(c.imag)]
curr_pos = complex(0, matrix[0].index("|"))
direction = complex(1, 0)

steps = 0
letters: list[str] = []
while True:
    curr_tile = coord2elem(curr_pos)
    if curr_tile.isalpha():
        letters.append(curr_tile)
    next_pos = curr_pos + direction
    match coord2elem(next_pos):
        case " ":
            steps += 1
            break
        case "+":
            for rotation in complex(0, 1), complex(0, -1):
                new_dir = direction * rotation
                new_step = next_pos + new_dir
                if 0 <= new_step.real < len(matrix) and 0 <= new_step.imag < len(matrix[0]):
                    if coord2elem(new_step) != " ":
                        direction = new_dir
                        curr_pos = new_step
                        steps += 2
                        break
        case _:
            curr_pos = next_pos
            steps += 1

print(f"Part 1: {"".join(letters)}")
print(f"Part 2: {steps}")
