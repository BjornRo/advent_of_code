with open("in/d2.txt") as f:
    KEYCODE = f.read().rstrip().split()


def mission_improbable(keypad: tuple[tuple[str, ...], ...]):
    pos, code = next([i, j] for i, row in enumerate(keypad) for j, col in enumerate(row) if col == "5"), ""
    for move in KEYCODE:
        for key in move:
            row, col = pos
            match key:
                case "U":
                    row -= 1
                case "D":
                    row += 1
                case "L":
                    col -= 1
                case "R":
                    col += 1
            if keypad[row][col] != "0":
                pos[:] = row, col
        code += keypad[pos[0]][pos[1]]
    return code


pad = lambda x: zip(*map(lambda y: ("0", *y, "0"), x))
print("Part 1:", mission_improbable(tuple(pad(pad(("123", "456", "789"))))))
print("Part 2:", mission_improbable(tuple(pad(pad(("00100", "02340", "56789", "0ABC0", "00D00"))))))
