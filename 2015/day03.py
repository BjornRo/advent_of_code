with open("in/d3.txt") as f:
    visited, santa, robot = set(), {(0, 0)}, set()
    row = col = srow = scol = rrow = rcol = 0
    for i, c in enumerate(f.read()):
        if (k := (row, col)) not in visited:
            visited.add(k)
        match c:
            case "^":
                row -= 1
                if i % 2 == 0:
                    srow -= 1
                else:
                    rrow -= 1
            case "v":
                row += 1
                if i % 2 == 0:
                    srow += 1
                else:
                    rrow += 1
            case ">":
                col += 1
                if i % 2 == 0:
                    scol += 1
                else:
                    rcol += 1
            case "<":
                col -= 1
                if i % 2 == 0:
                    scol -= 1
                else:
                    rcol -= 1
        if i % 2 == 0:
            if (k := (srow, scol)) not in santa:
                santa.add(k)  # type:ignore
        else:
            if (k := (rrow, rcol)) not in robot:
                robot.add(k)
    print("Part 1:", len(visited))
    print("Part 2:", len(santa | robot))
