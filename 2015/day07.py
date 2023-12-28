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

from collections import defaultdict, deque

circuits = defaultdict(int)
with open("in/d7.txt") as f:
    operations = deque(sorted((x.rstrip().split(" -> ") for x in f), key=lambda x: x[0].isdigit()))
while True:
    op, targ = operations.pop()
    if not op.isdigit():
        operations.append([op, targ])
        break
    circuits[targ] = int(op)

while operations:
    _op, targ = operations.popleft()
    match _op.split():
        case _, symb:  # NOT. There are no digit symbols with NOT.
            if symb in circuits:
                continue
        case symb1, op, symb2:
            if symb1.isdigit() and symb2 in circuits:
                continue
            if symb1.isdigit() and symb2.isdigit():
                continue
            if symb1 in circuits and symb2.isdigit():
                print("yes")
                continue
            if symb1 in circuits and symb2 in circuits:
                continue

    # We cannot do any operations yet
    # operations.append([_op, targ])
