from collections import defaultdict
from enum import IntEnum, auto
from typing import Literal

with open("in/d17.txt") as f:
    p = [0]  # padding
    raw_mat = tuple(zip(*(p + list(y) + p for y in zip(*(p + [int(c) for c in x.rstrip()] + p for x in f)))))


class Dir(IntEnum):
    UP = auto()
    DOWN = auto()
    LEFT = auto()
    RIGHT = auto()


MAX_ROW, MAX_COL = len(raw_mat) - 2, len(raw_mat[0]) - 2


IsDone = bool
PathSum = int
Path = list[tuple[int, int]]

"""
Until nothing has reached the end.
Search the matrix for one path and compare to 'finished_value'.
    If the current path has a larger sum than 'finished_value', this is rejected in the next state.
    When one path has found the end:
        Set 'finished_value' to the PathSum -> All values will be smaller than infinity.
"""
State = tuple[int, int, Dir | None, int]
finished_value: int | float = float("inf")
visited = set()
opposite = {Dir.UP: Dir.DOWN, Dir.DOWN: Dir.UP, Dir.LEFT: Dir.RIGHT, Dir.RIGHT: Dir.LEFT}
end_point = (MAX_ROW, MAX_COL)
current_states: dict[State, tuple[PathSum, Path]] = {((1, 1, None, 0)): (0, [])}
next_states: dict[State, tuple[PathSum, Path]] = {}
all_paths = []
while current_states:
    for ((row, col, dir, steps)), (path_sum, path) in current_states.items():
        for i in Dir:
            if dir is not None and i == opposite[dir]:
                continue
            _row, _col = row, col
            match i:
                case Dir.UP:
                    _row -= 1
                case Dir.DOWN:
                    _row += 1
                case Dir.LEFT:
                    _col -= 1
                case Dir.RIGHT:
                    _col += 1
            index_value = raw_mat[_row][_col]
            rowcol = (_row, _col)
            if rowcol == end_point:
                finished_value = min(path_sum + index_value, finished_value)
                all_paths.append(path + [rowcol])
                continue
            if index_value:
                if dir == i:
                    _steps = steps + 1
                    if _steps >= 3:
                        continue
                else:
                    _steps = 0
                    if dir is None:
                        _steps = 1
                new_path_sum = path_sum + index_value
                # if path == [(1, 2), (1, 3), (2, 3), (2, 4), (2, 5), (2, 6), (1, 6)]:
                #     print(repr(dir), repr(i), path_sum, index_value, rowcol)
                #     breakpoint()
                if new_path_sum < finished_value:
                    existing_key = (*rowcol, i, _steps)
                    existing_state = next_states.get(existing_key)
                    if existing_state is None:
                        next_states[existing_key] = (new_path_sum, path + [rowcol])
                    elif new_path_sum < existing_state[0]:
                        next_states[existing_key] = (new_path_sum, path + [rowcol])
    current_states.clear()
    current_states.update(next_states)
    next_states.clear()
print(finished_value)


from copy import deepcopy

print(len(all_paths))
zeros = [list(x) for x in deepcopy(raw_mat)]
for row, col in all_paths[-1]:
    zeros[row][col] = 0

for r in zeros:
    print(r)
