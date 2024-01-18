def assembly(ins_len: int, registers: dict[str, int], pc=0):
    ins = list(instructions)
    while pc < ins_len:
        match ins[pc]:
            case "cpy", val, reg:
                registers[reg] = int(val) if val.isdigit() else registers[val]
            case "inc", reg:
                registers[reg] += 1
            case "tgl", reg:
                match ins[pc + registers[reg]]:
                    case i, r1:
                        ins[pc + registers[reg]] = ("dec" if i == "inc" else "inc", r1)
                    case i, r1, r2:
                        if i == "jnz":
                            if not r2[-1].isdigit():
                                ins[pc + registers[reg]] = ("cpy", r1, r2)
                        else:
                            ins[pc + registers[reg]] = ("jnz", r1, r2)
            case "dec", reg:
                registers[reg] -= 1
            case "jnz", r1, r2:
                if (int(r1) if r1[-1].isdigit() else registers[r1]) != 0:
                    pc += (int(r2) if r2[-1].isdigit() else registers[r2]) - 1
        pc += 1
    return registers["a"]


with open("in/d23.txt") as f:
    instructions = tuple(tuple(x.rstrip().split()) for x in f)
print("Part 1:", assembly(len(instructions), {k: 0 for k in "abcd"}))
# print("Part 2:", assembly(len(instructions), {k: 1 if k == "c" else 0 for k in "abcd"}))
