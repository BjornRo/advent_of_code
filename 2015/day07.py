from collections import deque


def operate(val1: int, op: str, val2: int) -> int:
    match op:
        case "LSHIFT":
            return val1 << val2
        case "RSHIFT":
            return val1 >> val2
        case "AND":
            return val1 & val2
    return val1 | val2  # "OR"


def assembler(operations: deque[list[str]], part2: int = 0):
    circuits: dict[str, int] = {}
    while True:
        _op, targ = operations.popleft()
        match _op.split():
            case [symb] if symb in circuits:
                return circuits[symb]  # "a"
            case [symb] if symb.isdigit():
                circuits[targ] = part2 if part2 and targ == "b" else int(symb)
            case ["NOT", symb] if symb in circuits:  # There are no digit symbols with NOT.
                circuits[targ] = 65536 + ~circuits[symb]
            case [symb1, op, symb2] if symb1.isdigit() and symb2 in circuits:
                circuits[targ] = operate(int(symb1), op, circuits[symb2])
            case [symb1, op, symb2] if symb1 in circuits and symb2.isdigit():
                circuits[targ] = operate(circuits[symb1], op, int(symb2))
            case [symb1, op, symb2] if symb1 in circuits and symb2 in circuits:
                circuits[targ] = operate(circuits[symb1], op, circuits[symb2])  # No: digit | op | digit.
            case _:  # We cannot do any operations yet
                operations.append([_op, targ])


with open("in/d7.txt") as f:
    operations = deque(x.rstrip().split(" -> ") for x in f)
part1 = assembler(deque(operations))
print("Part 1:", part1)
print("Part 2:", assembler(operations, part1))
