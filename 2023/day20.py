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


def tmi(part1: int) -> int:
    m: dict[Name, FlipFlop | Conjunct] = {}
    to_inverters: list[tuple[Name, Name]] = []
    for cmd, (pfx, cmds) in onlycast.items():
        m[cmd] = FlipFlop() if pfx == "%" else Conjunct()
        for next_cmd in cmds:
            if next_cmd in onlycast and onlycast[next_cmd][0] == "&":
                to_inverters.append((next_cmd, cmd))
    for conj, cmd in to_inverters:
        if (c := m[conj]) and isinstance(c, Conjunct):
            c.inputs[cmd] = False
    k = next(c for c, (_, i) in onlycast.items() if "rx" in i)
    h, e, l, p = [0, 0], deque(), 0, [0] * sum([k in c for _, (_, c) in onlycast.items()])
    if (c := m[k]) and isinstance(c, Conjunct) and (d := c.inputs):
        while l := l + 1:
            h[0] += 1 + len(broadcaster)
            for cmd in broadcaster:
                e.append(cmd)
                m[cmd].recv("", False)
            while e and (cmd := e.popleft()):
                for next_cmd in onlycast[cmd][1]:
                    h[m[cmd].state] += 1
                    if next_cmd in onlycast:
                        if m[next_cmd].recv(cmd, m[cmd].state):
                            e.append(next_cmd)
                        if not part1 and next_cmd == k and any(d.values()):
                            for i, v in enumerate(d.values()):
                                if v and not p[i]:
                                    p[i] = l
                                    if all(p):
                                        return lcm(*p)
            if part1 and l == 1000:
                break
    return h[0] * h[1]


print("Part 1:", tmi(1000))
print("Part 2:", tmi(0))
