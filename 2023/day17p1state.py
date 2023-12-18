from enum import IntEnum, auto

with open("in/d17.txt") as f:
    p = [0]  # padding
    raw_mat = tuple(zip(*(p + list(y) + p for y in zip(*(p + [int(c) for c in x.rstrip()] + p for x in f)))))


class Dir(IntEnum):
    UP = auto()
    DOWN = auto()
    LEFT = auto()
    RIGHT = auto()


END = (len(raw_mat) - 2, len(raw_mat[0]) - 2)

PathSum = int
Path = list[tuple[int, int]]
State = tuple[int, int, Dir, int]

finished_value: int | float = float("inf")
current_states: dict[State, PathSum] = {((1, 1, Dir.RIGHT, 1)): 0, ((1, 1, Dir.DOWN, 1)): 0}
next_states: dict[State, PathSum] = {}

while current_states:
    for (I, Ii, II, I_), path_sum in current_states.items():
        if (I, Ii) == END:
            finished_value = min(path_sum, finished_value)
            continue
        if path_sum >= finished_value:
            continue
        for i in Dir:
            if i == {Dir.UP: Dir.DOWN, Dir.DOWN: Dir.UP, Dir.LEFT: Dir.RIGHT, Dir.RIGHT: Dir.LEFT}[II]:
                continue
            _row, _col = I, Ii
            match i:
                case Dir.UP:
                    _row -= 1
                case Dir.DOWN:
                    _row += 1
                case Dir.LEFT:
                    _col -= 1
                case Dir.RIGHT:
                    _col += 1
            if index_value := raw_mat[_row][_col]:
                if i == II:
                    if I_ >= 3:
                        continue
                    _steps = I_ + 1
                else:
                    _steps = 1
                existing_sum = next_states.get((_row, _col, i, _steps))
                if existing_sum is None or existing_sum > index_value + path_sum:
                    next_states[(_row, _col, i, _steps)] = index_value + path_sum
    current_states.clear()
    current_states.update(sorted(next_states.items(), key=lambda x: x[1]))
    next_states.clear()
print("Part 1:", finished_value)
