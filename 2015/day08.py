with open("in/d8.txt") as f:
    total1 = total2 = 0
    for x in (r.rstrip() for r in f if r.strip()):
        total1 += len(x) - len(eval(x))  # Do not do eval(..) unless you are sure about input! :)
        total2 += len(x.replace("\\", "\\\\").replace('"', r"\"")) + 2 - len(x)
    print("Part 1:", total1)
    print("Part 2:", total2)
