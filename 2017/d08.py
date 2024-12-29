from collections import defaultdict
from operator import eq, ge, gt, le, lt, ne
from typing import Callable

with open("in/d08.txt") as f:
    data = [x.rstrip().split(" ") for x in f]


def get_op(op: str) -> Callable[[int, int], bool]:
    match op:
        case "==":
            return eq
        case "!=":
            return ne
        case ">":
            return gt
        case ">=":
            return ge
        case "<":
            return lt
        case "<=":
            return le
    raise Exception


def solver(instructions: list[list[str]]) -> tuple[int, int]:
    registers: dict[str, int] = defaultdict(int)
    max_max = 0

    for i in instructions:
        reg_x, dec_inc, value_x, _, reg_y, op, value_y = i
        if get_op(op)(registers[reg_y], int(value_y)):
            registers[reg_x] += int(value_x) if (dec_inc == "inc") else -int(value_x)
        max_max = max(max_max, max(registers.values()))
    return max(registers.values()), max_max


p1, p2 = solver(data)

print(f"Part 1: {p1}")
print(f"Part 2: {p2}")
