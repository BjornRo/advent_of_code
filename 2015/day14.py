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
        if self.is_speeding:
            self.distance += self.speed
            self.current_duration += 1
            if self.current_duration == self.burst:
                self.is_speeding = False
                self.current_duration = 0
        else:
            self.current_duration += 1
            if self.current_duration == self.rest:
                self.is_speeding = True
                self.current_duration = 0
        return self.distance


time_limit, max_val = 2503, 0
animal_control, points = [], []
with open("in/d14.txt") as f:
    for speed, duration, rest in (map(int, re.findall(r"\d+", s)) for s in f):
        animal_control.append(Raindear(speed, duration, rest))
        points.append(0)
        _time_limit, distance = time_limit, 0
        while _time_limit > 0:
            maxdiff = min(_time_limit, duration)
            distance += speed * maxdiff
            _time_limit -= maxdiff + rest
        max_val = max(max_val, distance)
print("Part 1:", max_val)

for _ in range(time_limit):
    distances = [a.tick() for a in animal_control]
    for i, dist in enumerate(distances):
        if dist >= max(distances):
            points[i] += 1
print("Part 2:", max(points))
