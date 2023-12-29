import re
from dataclasses import dataclass


@dataclass
class Raindear:
    speed: int
    burst: int
    rest: int
    distance = 0
    is_speeding = True
    current_duration = 0

    def tick(self):
        self.current_duration += 1
        if self.is_speeding:
            self.distance += self.speed
            if self.current_duration == self.burst:
                self.current_duration, self.is_speeding = 0, False
        else:
            if self.current_duration == self.rest:
                self.current_duration, self.is_speeding = 0, True
        return self.distance


with open("in/d14.txt") as f:
    animal_control = [Raindear(spd, dur, rest) for spd, dur, rest in (map(int, re.findall(r"\d+", s)) for s in f)]

points = [0] * len(animal_control)
for _ in range(2503):
    distances = [a.tick() for a in animal_control]
    for i, dist in enumerate(distances):
        if dist >= max(distances):
            points[i] += 1
print("Part 1:", max(a.distance for a in animal_control))
print("Part 2:", max(points))
