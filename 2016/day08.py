with open("in/d8.txt") as f:
    instructions = tuple(x.strip().replace("y=", "").replace("x=", "").replace("by ", "").split() for x in f)

ROW, COL = 6, 50
screen = [[False] * COL for _ in range(ROW)]

for i in instructions:
    match i:
        case ["rect", dims]:
            row, col = map(int, dims.split("x")[::-1])
            for i in range(row):
                for j in range(col):
                    screen[i][j] = True
        case [_, "row", *rp]:
            (row, pixel), new_vals = map(int, rp), [False] * COL
            for i in range(COL):
                new_vals[(i + pixel) % COL] = screen[row][i]
            for i, v in enumerate(new_vals):
                screen[row][i] = v
        case [_, "column", *rp]:
            (col, pixel), new_vals = map(int, rp), [False] * ROW
            for i in range(ROW):
                new_vals[(i + pixel) % ROW] = screen[i][col]
            for i, v in enumerate(new_vals):
                screen[i][col] = v

display_to_ascii = {
    (" ## ", "#  #", "#  #", "####", "#  #", "#  #"): "A",
    ("### ", "#  #", "### ", "#  #", "#  #", "### "): "B",
    ("####", "#   ", "### ", "#   ", "#   ", "#   "): "F",
    ("  ##", "   #", "   #", "   #", "#  #", " ## "): "J",
    ("### ", "#  #", "#  #", "### ", "#   ", "#   "): "P",
    (" ###", "#   ", "#   ", " ## ", "   #", "### "): "S",
    ("#  #", "#  #", "#  #", "#  #", "#  #", " ## "): "U",
    ("####", "   #", "  # ", " #  ", "#   ", "####"): "Z",
}
letters, letter = [], []
for i in zip(*screen):
    if (s := "".join("#" if x else " " for x in i)) and "#" in s:
        letter.append(s)
    else:
        letters.append(display_to_ascii[tuple("".join(x) for x in zip(*letter))])  # type:ignore
        letter *= 0

print("Part 1:", sum(c for row in screen for c in row))
print("Part 2:", "".join(letters))
