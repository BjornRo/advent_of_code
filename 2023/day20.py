from collections import deque
from dataclasses import dataclass, field

Priority = int
Name = Prefix = str

onlycast: dict[str, tuple[Prefix, list[Name]]]
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

    def recv(self, _cmd: Name, new_state: bool) -> bool:
        if not new_state:
            self.state = not self.state
            return True
        return False


# 8 low pulses and 4 high pulses are sent.
def tmi(presses: int):
    modules: dict[Name, FlipFlop | Conjunct] = {}
    to_inverters: list[tuple[Name, Name]] = []
    for cmd, (pfx, cmds) in onlycast.items():
        match pfx:
            case "%":
                modules[cmd] = FlipFlop()
            case "&":
                modules[cmd] = Conjunct()
        for next_cmd in cmds:
            if next_cmd in onlycast and onlycast[next_cmd][0] == "&":
                to_inverters.append((next_cmd, cmd))
    for conj, cmd in to_inverters:
        modules[conj].inputs[cmd] = False  # type:ignore
    # End init

    queue: deque[Name] = deque()
    low_high_count = [0, 0]

    for _ in range(presses):
        low_high_count[0] += 1
        for cmd in broadcaster:
            queue.append(cmd)
            modules[cmd].recv("", False)
            low_high_count[0] += 1
        while queue:
            cmd = queue.popleft()
            send = modules[cmd]
            for next_cmd in onlycast[cmd][1]:
                low_high_count[send.state] += 1
                if next_cmd in onlycast:
                    recv = modules[next_cmd]
                    match recv:
                        case FlipFlop():
                            if recv.recv(cmd, send.state):
                                queue.append(next_cmd)
                        case Conjunct():
                            recv.recv(cmd, send.state)
                            queue.append(next_cmd)
    print(low_high_count)


tmi(1000)
