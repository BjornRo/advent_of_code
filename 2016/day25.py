def assembly(instructions: list[tuple[str, ...]], ins_len: int, a_val: int, sensitivity: int, pc=0):
    a, b, k, registers = set(), set(), 0, {k: a_val if k == "a" else 0 for k in "abcd"}
    while pc < ins_len:
        match instructions[pc]:
            case "cpy", val, reg:
                registers[reg] = int(val) if val[-1].isdigit() else registers[val]
            case "inc", reg:
                registers[reg] += 1
            case "tgl", reg:
                if (pcr := pc + registers[reg]) < ins_len:
                    match instructions[pcr]:
                        case i, r1:
                            instructions[pcr] = ("dec" if i == "inc" else "inc", r1)
                        case i, r1, r2:
                            if i != "jnz":
                                instructions[pcr] = ("jnz", r1, r2)
                            elif not r2[-1].isdigit():
                                instructions[pcr] = ("cpy", r1, r2)
            case "dec", reg:
                registers[reg] -= 1
            case "jnz", r1, r2:
                if (int(r1) if r1[-1].isdigit() else registers[r1]) != 0:
                    pc += (int(r2) if r2[-1].isdigit() else registers[r2]) - 1
            case "out", reg:
                (a if k % 2 == 0 else b).add(registers[reg])
                if len(a) >= 2 or len(b) >= 2:
                    return False
                if k >= sensitivity:
                    return True
                k += 1
        pc += 1
    return False


with open("in/d25.txt") as f:
    instructions = tuple(tuple(x.rstrip().split()) for x in f)
for i in range(1_000):
    if assembly(list(instructions), len(instructions), i, sensitivity=10):
        print("Part 1:", i)
        break
