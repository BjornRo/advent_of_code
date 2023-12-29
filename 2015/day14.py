import re
from dataclasses import dataclass


@dataclass
class Raindear:
    speed: int
    speed_len: int
    rest_len: int
    distance = current_duration = is_resting = 0

    def tick(self):
        self.current_duration += 1
        if not self.is_resting:
            self.distance += self.speed
            if self.current_duration == self.speed_len:
                self.current_duration, self.is_resting = 0, True
        elif self.current_duration == self.rest_len:
            self.current_duration, self.is_resting = 0, False
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
