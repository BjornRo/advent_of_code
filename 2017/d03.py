import math

data = 368078


def part1(number: int) -> int:
    width = math.ceil(number**0.5)
    sq_width = width * width

    mid_to_outer = width // 2
    center = sq_width - width // 2
    return abs(number - center) + mid_to_outer


def part2(number: int) -> int:
    width = math.ceil(number**0.5)
    width_p2 = width + 2

    matrix = [[0] * width_p2 for _ in range(width_p2)]

    turn_left = complex(0, 1)
    dir = complex(0, 1)
    pos = complex(width_p2 // 2, width_p2 // 2)

    complex_to_int = lambda c: map(int, (c.real, c.imag))
    r, c = complex_to_int(pos)
    matrix[r][c] = 1

    first = True
    while True:
        if first:
            first = False
        else:
            r, c = complex_to_int(pos)
            matrix[r][c] = sum(matrix[r + dr][c + dc] for dr in range(-1, 2) for dc in range(-1, 2))
            if matrix[r][c] > number:
                return matrix[r][c]

        new_dir = dir * turn_left
        new_pos = pos + dir
        dr, dc = complex_to_int(new_pos)
        if matrix[dr][dc] == 0:
            pos = new_pos
            dir = new_dir
        else:
            pos += dir * complex(0, -1)


print(f"Part 1: {part1(data)}")
print(f"Part 2: {part2(data)}")
