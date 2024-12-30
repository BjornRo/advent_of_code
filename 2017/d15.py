with open("in/d15.txt") as f:
    A_value, B_value = [int(x.rstrip().rsplit(" ", 1)[-1]) for x in f]


def part1(a_val: int, b_val: int):
    def generator(start_value: int, factor: int):
        while True:
            start_value *= factor
            start_value %= 2147483647
            yield start_value

    gen_A = iter(generator(a_val, factor=16807))
    gen_B = iter(generator(b_val, factor=48271))
    matches = 0
    for _ in range(40_000_000):
        if next(gen_A) & 0xFFFF == next(gen_B) & 0xFFFF:
            matches += 1
    return matches


def part2(a_val: int, b_val: int):
    def generator(start_value: int, factor: int, multiplies: int):
        while True:
            start_value *= factor
            start_value %= 2147483647
            if start_value % multiplies == 0:
                yield start_value

    gen_A = iter(generator(a_val, factor=16807, multiplies=4))
    gen_B = iter(generator(b_val, factor=48271, multiplies=8))
    matches = 0
    for _ in range(5_000_000):
        if next(gen_A) & 0xFFFF == next(gen_B) & 0xFFFF:
            matches += 1
    return matches


print(f"Part 1: {part1(A_value, B_value)}")
print(f"Part 2: {part2(A_value, B_value)}")
