with open("in/d18.txt") as f:
    p = [False]  # Pad False around the map for easier bound checking
    lighters = [*map(list, zip(*((*p, *r, *p) for r in (zip(*(p + [c == "#" for c in r.rstrip()] + p for r in f))))))]

MAX = len(lighters) - 1


def light_killer(chart: list[list[bool]], steps: int, part2: bool = False):
    chart = [[*r] for r in chart]  # Copy chart
    mood_killer: list[tuple[bool, int, int]] = []  # Lights to turn on/off
    corners = set((r, c) for r in range(1, MAX, MAX - 2) for c in range(1, MAX, MAX - 2))
    if part2:
        for r, c in corners:
            chart[r][c] = True
    for _ in range(steps):
        for i in range(1, MAX):
            for j in range(1, MAX):
                if not (part2 and (i, j) in corners):
                    s = sum(chart[i + k][j + l] for k in range(-1, 2) for l in range(-1, 2))
                    if not chart[i][j] and s == 3:
                        mood_killer.append((True, i, j))
                    elif chart[i][j] and s not in {3, 4}:  # Counts itself -> (2+1, 3+1)
                        mood_killer.append((False, i, j))
        while mood_killer:
            onoff, row, col = mood_killer.pop()
            chart[row][col] = onoff
    return chart


uncharted = light_killer(lighters, 100)
print("Part 1:", sum(uncharted[i][j] for i in range(1, MAX) for j in range(1, MAX)))
uncharted = light_killer(lighters, 100, True)
print("Part 2:", sum(uncharted[i][j] for i in range(1, MAX) for j in range(1, MAX)))
