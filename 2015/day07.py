"""123 -> x
456 -> y
x AND y -> d
x OR y -> e
x LSHIFT 2 -> f
y RSHIFT 2 -> g
NOT x -> h
NOT y -> i

d: 72
e: 507
f: 492
g: 114
h: 65412
i: 65079
x: 123
y: 456 """

from collections import deque

with open("in/d7.txt") as f:
    operations = deque(x.rstrip().split(" -> ") for x in f)


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
                continue
            if symb1.isdigit() and symb2.isdigit():
                circuits[targ] = operate(int(symb1), op, int(symb2))
                continue
            if symb1 in circuits and symb2.isdigit():
                circuits[targ] = operate(circuits[symb1], op, int(symb2))
                continue
            if symb1 in circuits and symb2 in circuits:
                circuits[targ] = operate(circuits[symb1], op, circuits[symb2])
                continue
        case [symb]:
            if symb.isdigit():
                circuits[targ] = int(symb)
                continue
            if symb in circuits:
                circuits[targ] = circuits[symb]
                break
    operations.append([_op, targ])  # We cannot do any operations yet

print("Part 1:", circuits["a"])
