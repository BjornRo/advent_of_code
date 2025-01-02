from string import ascii_lowercase

with open("in/d23.txt") as f:
    instructions = [x.rstrip().split(" ") for x in f]


def program(a: int):
    reg_or_val = lambda registers, value: registers[value] if value.isalpha() else int(value)
    registers = {x: 0 for x in ascii_lowercase[:8]}
    registers["a"] = a
    muls = 0
    pc = 0
    while pc < len(instructions):
        match instructions[pc]:
            case "set", reg, val:
                registers[reg] = reg_or_val(registers, val)
            case "sub", reg, val:
                registers[reg] -= reg_or_val(registers, val)
            case "mul", reg, val:
                registers[reg] *= reg_or_val(registers, val)
                muls += 1
            case "jnz", reg, val:
                if reg_or_val(registers, reg) != 0:
                    pc += int(val) - 1
            case _:
                raise Exception
        if a == 1 and registers["f"] == 1:
            break
        pc += 1

    return muls, registers


def part2():
    not_prime = lambda a: a < 2 or any(a % x == 0 for x in range(2, int(a**0.5) + 1))
    registers = program(1)[1]

    h = 0
    for i in range(registers["b"], registers["c"] + 1, 17):
        if not_prime(i):
            h += 1
    return h


print(f"Part 1: {program(0)[0]}")
print(f"Part 2: {part2()}")
