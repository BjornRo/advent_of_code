import re
from collections import defaultdict
from dataclasses import dataclass

with open("in/d25.txt") as f:
    data = f.read().split("\n\n")

type StateName = str


@dataclass
class State:
    name: StateName
    zero_state: StateName
    zero_dir: int
    zero_val: int
    one_state: StateName
    one_dir: int
    one_val: int

    def get_zero(self):
        return self.zero_state, self.zero_val, self.zero_dir

    def get_one(self):
        return self.one_state, self.one_val, self.one_dir


states: dict[StateName, State] = {}
for i in data[1:]:
    st, _, zero_val, zero_dir, zero_st, _, one_val, one_dir, one_st = re.findall(r"(state [A-H]|\d|left|right)", i)
    states[st[-1]] = State(
        name=st[-1],
        zero_state=zero_st[-1],
        zero_dir=-1 if zero_dir == "left" else 1,
        zero_val=int(zero_val),
        one_state=one_st[-1],
        one_dir=-1 if one_dir == "left" else 1,
        one_val=int(one_val),
    )


state: State = states[data[0].split(".")[0][-1]]
position = 0
tape: dict[int, int] = defaultdict(int)

for _ in range(int("".join(x for x in data[0] if x.isdigit()))):
    next_state, value, direction = state.get_zero() if tape[position] == 0 else state.get_one()
    tape[position] = value
    position += direction
    state = states[next_state]

print(f"Part 1: {sum(tape.values())}")
