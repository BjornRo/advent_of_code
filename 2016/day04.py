with open("in/d4.txt") as f:
    wroom = tuple(tuple(r.rstrip()[:-1].replace("[", "-").split("-")) for r in f)
