with open("in/d11.txt") as f:
    data = f.read().rstrip().split(",")


def solver(steps: list[str]) -> tuple[int, int]:
    def manhattan_half(a: complex, b: complex):
        return int(abs(a.real - b.real) + abs(a.imag - b.imag)) // 2

    start = complex(0, 0)
    child_process = start
    max_max = 0
    for i in steps:
        match i:
            case "nw":
                child_process += complex(-1, -1)
            case "n":
                child_process += complex(-2, 0)
            case "ne":
                child_process += complex(-1, 1)
            case "sw":
                child_process += complex(1, -1)
            case "s":
                child_process += complex(2, 0)
            case "se":
                child_process += complex(1, 1)
            case x:
                raise Exception(x)
        max_max = max(max_max, manhattan_half(start, child_process))
    return manhattan_half(start, child_process), max_max


p1, p2 = solver(data)
print(f"Part 1: {p1}")
print(f"Part 2: {p2}")
