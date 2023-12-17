from collections import defaultdict
from copy import deepcopy
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


PathSum = int
Path = list[tuple[int, int]]

"""
Not correct but gave me enough range to guess the last 3 numbers
"""
State = tuple[int, int, Dir, int]
finished_value: int | float = float("inf")
visited = set()
opposite = {Dir.UP: Dir.DOWN, Dir.DOWN: Dir.UP, Dir.LEFT: Dir.RIGHT, Dir.RIGHT: Dir.LEFT}
end_point = (MAX_ROW, MAX_COL)
current_states: dict[State, tuple[PathSum, Path]] = {((1, 3, Dir.RIGHT, 4)): (0, []), ((3, 1, Dir.DOWN, 3)): (0, [])} #
next_states: dict[State, tuple[PathSum, Path]] = {}
all_paths = []
while current_states:
    for ((row, col, dir, steps)), (path_sum, path) in current_states.items():
        for i in Dir:
            if i == opposite[dir]:
                continue
            _steps = steps + 1
            if (dir != i and _steps <= 3) or _steps >= 11:
                # print(steps, dir)
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
            if index_value:
                if dir != i:
                    _steps = 0
                new_path_sum = path_sum + index_value
                # if path == [(1, 2), (1, 3), (2, 3), (2, 4), (2, 5), (2, 6), (1, 6)]:
                #     print(repr(dir), repr(i), path_sum, index_value, rowcol)
                #     breakpoint()
                if new_path_sum <= finished_value:
                    # print()
                    # zeros = [list(x) for x in deepcopy(raw_mat)]
                    # for xrow, xcol in path:
                    #     zeros[xrow][xcol] = int(dir)
                    # for r in [dx[1:-1] for dx in zeros[1:-1]]:
                    #     print(r)
                    # breakpoint()
                    if rowcol == end_point and _steps >= 3:
                        print(finished_value)
                        finished_value = min(path_sum + index_value, finished_value)
                        all_paths.append(path + [rowcol])
                        continue
                    existing_key = (*rowcol, i, _steps)
                    existing_state = next_states.get(existing_key)
                    if existing_state is None:
                        next_states[existing_key] = (new_path_sum, path)
                    elif new_path_sum < existing_state[0]:
                        next_states[existing_key] = (new_path_sum, path)
    current_states.clear()
    current_states.update(next_states)
    next_states.clear()
print(finished_value)




# print(len(all_paths))
# total = 0
# zeros = [list(x) for x in deepcopy(raw_mat)]
# for row, col in all_paths[-1]:
#     total += zeros[row][col]
#     zeros[row][col] = 0
# print(total)


# for r in [x[1:-1] for x in zeros[1:-1]]:
#     print(r)
