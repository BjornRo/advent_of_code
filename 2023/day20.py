from collections import deque
from dataclasses import dataclass, field
from math import lcm

Name = Prefix = str
onlycast: dict[Name, tuple[Prefix, list[Name]]]
with open("in/d20.txt") as f:
    onlycast = {k[1:]: (k[0], [e.strip() for e in v.split(",")]) for k, v in (x.strip().split(" -> ") for x in f)}
    broadcaster = onlycast.pop("roadcaster")[1]


@dataclass
class Conjunct:
    inputs: dict[Name, bool] = field(default_factory=dict)

    @property
    def state(self):
        return not all(self.inputs.values())

    def recv(self, cmd: Name, new_state: bool) -> bool:
        self.inputs[cmd] = new_state
        return True


@dataclass
class FlipFlop:
    state: bool = False

    def recv(self, _: Name, new_state: bool) -> bool:
        if not new_state:
            self.state = not self.state
            return True
        return False


def floppyness() -> dict[Name, FlipFlop | Conjunct]:
    modules: dict[Name, FlipFlop | Conjunct] = {}
    to_inverters: list[tuple[Name, Name]] = []
    for cmd, (pfx, cmds) in onlycast.items():
        modules[cmd] = FlipFlop() if pfx == "%" else Conjunct()
        for next_cmd in cmds:
            if next_cmd in onlycast and onlycast[next_cmd][0] == "&":
                to_inverters.append((next_cmd, cmd))
    for conj, cmd in to_inverters:
        if (c := modules[conj]) and isinstance(c, Conjunct):
            c.inputs[cmd] = False
    return modules


def tmi(presses: int) -> int:
    modules, queue, low_high_count = floppyness(), deque(), [0, 0]
    for _ in range(presses):
        low_high_count[0] += 1 + len(broadcaster)
        for cmd in broadcaster:
            queue.append(cmd)
            modules[cmd].recv("", False)
        while queue and (cmd := queue.popleft()):
            for next_cmd in onlycast[cmd][1]:
                low_high_count[modules[cmd].state] += 1
                if next_cmd in onlycast and modules[next_cmd].recv(cmd, modules[cmd].state):
                    queue.append(next_cmd)
    return low_high_count[0] * low_high_count[1]


def bmi() -> int:
    k = [c for c, (_, i) in onlycast.items() if "rx" in i][0]
    h, e, l, p = floppyness(), deque(), 0, [0] * sum([k in c for _, (_, c) in onlycast.items()])
    if (c := h[k]) and isinstance(c, Conjunct) and (d := c.inputs):
        while l := l + 1:
            for cmd in broadcaster:
                e.append(cmd)
                h[cmd].recv("", False)
            while e and (cmd := e.popleft()):
                for next_cmd in onlycast[cmd][1]:
                    if next_cmd in onlycast:
                        if h[next_cmd].recv(cmd, h[cmd].state):
                            e.append(next_cmd)
                        if next_cmd == k and any(d.values()):
                            for i, v in enumerate(d.values()):
                                if v and not p[i]:
                                    p[i] = l
                                    if all(p):
                                        return lcm(*p)
    assert False


print("Part 1:", tmi(1000))
print("Part 2:", bmi())
