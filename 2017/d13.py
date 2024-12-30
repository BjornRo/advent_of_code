import math
from copy import deepcopy
from dataclasses import dataclass
from itertools import count


@dataclass
class Layer:
    index: int
    max_pos: int
    curr_pos: int
    total_range: int
    direction = 1

    @staticmethod
    def init(index: int, max_pos: int):
        return Layer(int(index), int(max_pos), 0, int(max_pos) * 2 - 2)

    def caught(self, me_index: int):
        if self.curr_pos == 0 and self.index == me_index:
            return self.max_pos * self.index
        return 0

    def move(self):
        self.curr_pos += self.direction
        if self.curr_pos in (0, self.max_pos - 1):
            self.direction = -self.direction


with open("in/d13.txt") as f:
    layers = [Layer.init(a, b) for a, b in (map(int, x.rstrip().split(": ")) for x in f)]


def part1(layers: list[Layer], offset=0):
    layers_ = deepcopy(layers)
    for i in range(offset):
        for l in layers_:
            l.move()
    total = 0
    for i in range(layers_[-1].index + 1):
        total += sum([l.caught(i) for l in layers_])
        for l in layers_:
            l.move()
    return total


def part2(layers: list[Layer]):
    for i in count(100_000, math.gcd(*(x.total_range for x in layers))):
        if all(((j.index + i) % j.total_range) != 0 for j in layers):
            return i
    raise Exception


print(f"Part 1: {part1(layers)}")
print(f"Part 2: {part2(layers)}")
