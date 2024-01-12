with open("in/d1.txt") as f:
    maze = [(y[0], int(y[1:])) for y in (x.strip() for x in f.read().split(","))]

