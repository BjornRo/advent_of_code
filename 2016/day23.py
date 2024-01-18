def assembly(ins_len: int, registers: dict[str, int], instructions: list[tuple[str, ...]], pc=0):
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
        pc += 1
    return registers["a"]


with open("in/d23.txt") as f:
    instructions = tuple(tuple(x.rstrip().split()) for x in f)
print("Part 1:", assembly(len(instructions), {k: 7 if k == "a" else 0 for k in "abcd"}, list(instructions)))
print("Part 2:", assembly(len(instructions), {k: 12 if k == "a" else 0 for k in "abcd"}, list(instructions)))
