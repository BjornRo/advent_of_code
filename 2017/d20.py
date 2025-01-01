import re
from copy import deepcopy
from dataclasses import dataclass
from itertools import batched

Vec3 = tuple[int, int, int] | tuple[int, ...]


@dataclass
class Particle:
    index: int
    pos: Vec3
    vel: Vec3
    acc: Vec3

    @staticmethod
    def init(index, arr) -> "Particle":
        return Particle(index, tuple(arr[:3]), tuple(arr[3:6]), tuple(arr[6:]))

    def part1(self):
        s = lambda x: sum(abs(i) for i in x)
        return (s(self.acc), s(self.vel), s(self.pos), self.index)

    def tick(self):
        self.vel = tuple(a + b for a, b in zip(self.vel, self.acc))
        self.pos = tuple(a + b for a, b in zip(self.pos, self.vel))

    def eq(self, other: "Particle") -> bool:
        return all(a == b for a, b in zip(self.pos, other.pos))

    def __hash__(self):
        return hash(self.index)


with open("in/d20.txt") as f:
    particles = [Particle(i, *batched(map(int, re.findall(r"-*\d+", x)), 3)) for i, x in enumerate(f)]


def part2(particles: list[Particle], threshold=5):
    prts = deepcopy(particles)
    start_len = len(prts)
    while True:
        for p in prts:
            p.tick()

        collided = set()
        for i in range(len(prts) - 1):
            for j in range(i + 1, len(prts)):
                if prts[i].eq(prts[j]):
                    collided.add(prts[i])
                    collided.add(prts[j])
        for i in collided:
            prts.remove(i)

        if len(prts) != start_len:
            if not collided:
                threshold -= 1
                if threshold == 0:
                    return len(prts)
            else:
                threshold = 5


print(f"Part 1: {sorted([x.part1() for x in particles], key=lambda x: (x[0], x[1], x[2]))[0][-1]}")
print(f"Part 2: {part2(particles)}")
