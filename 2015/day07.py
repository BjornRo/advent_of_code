from collections import deque


def operate(val1: int, op: str, val2: int) -> int:
    match op:
        case "LSHIFT":
            return val1 << val2
        case "RSHIFT":
            return val1 >> val2
        case "AND":
            return val1 & val2
        case "OR":
            return val1 | val2
    assert False


def assembler(operations: deque[list[str]], part2: int = 0):
    circuits: dict[str, int] = {}
    while True:
        _op, targ = operations.popleft()
        match _op.split():
            case "NOT", symb:  # There are no digit symbols with NOT.
                if symb in circuits:
                    circuits[targ] = 65536 + ~circuits[symb]
                    continue
            case symb1, op, symb2:
                if symb1.isdigit() and symb2 in circuits:
                    circuits[targ] = operate(int(symb1), op, circuits[symb2])
                    continue  # symb1.isdigit() and symb2.isdigit() does not exist
                if symb1 in circuits and symb2.isdigit():
                    circuits[targ] = operate(circuits[symb1], op, int(symb2))
                    continue
                if symb1 in circuits and symb2 in circuits:
                    circuits[targ] = operate(circuits[symb1], op, circuits[symb2])
                    continue
            case [symb]:
                if symb.isdigit():
                    if part2 and targ == "b":
                        symb = part2
                    circuits[targ] = int(symb)
                    continue
                if symb in circuits:
                    return circuits[symb]  # "a"
        operations.append([_op, targ])  # We cannot do any operations yet


with open("in/d7.txt") as f:
    operations = [x.rstrip().split(" -> ") for x in f]


part1 = assembler(deque([x.copy() for x in operations]))
print("Part 1:", part1)
print("Part 2:", assembler(deque(operations), part1))
