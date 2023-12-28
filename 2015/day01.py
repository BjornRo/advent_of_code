with open("in/d1.txt") as f:
    n = j = 0
    for i, c in enumerate(f.read().rstrip(), 1):
        n += 1 if c == "(" else -1
        if not j and n < 0:
            j = i
    print("Part 1:", n)
    print("Part 2:", j)
