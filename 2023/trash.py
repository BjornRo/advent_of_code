
CoordRowCol = tuple[int, int]
PathSum = int


def astar(start: CoordRowCol, goal: CoordRowCol, h: int):
    open_set = set()
    came_from = {}

    g_score = 2


"""
Until nothing has reached the end.
Search the matrix for one path and compare to 'finished_value'.
    If the current path has a larger sum than 'finished_value', this is rejected in the next state.
    When one path has found the end:
        Set 'finished_value' to the PathSum -> All values will be smaller than infinity.
"""

State = tuple[Dir | None, int, PathSum]
finished_value: int | float = float("inf")
visited = set()
opposite = {Dir.UP: Dir.DOWN, Dir.DOWN: Dir.UP, Dir.LEFT: Dir.RIGHT, Dir.RIGHT: Dir.LEFT}
end_point = (MAX_ROW, MAX_COL)
current_states: dict[CoordRowCol, State] = {(1, 1): (None, 0, 0)}
next_states: dict[CoordRowCol, State] = {}
while current_states:
    for (row, col), (dir, steps, path_sum) in current_states.items():
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
                # print(finished_value)
                continue
            if index_value:
                if dir == i:
                    _steps = steps + 1
                    if _steps >= 3:
                        continue
                else:
                    _steps = 0
                    if dir is None:
                        _steps += 1
                new_path_sum = path_sum + index_value
                if new_path_sum < finished_value:
                    # if path == [(1, 2), (1, 3), (2, 3), (2, 4), (2, 5), (2, 6)]:  # (1,6)  23
                    #     print(path_sum, index_value, repr(dir), repr(i))
                    #     breakpoint()
                    existing_state = next_states.get(rowcol)
                    if existing_state is None:
                        next_states[rowcol] = (i, _steps, new_path_sum)
                        continue
                    _dir, _ssteps, _state_sum = existing_state
                    if rowcol == (2,3):
                        print(existing_state)
                        print((i, _steps, new_path_sum))
                        breakpoint()
                    if new_path_sum <= _state_sum and _steps < _ssteps:
                        # print(new_path_sum, _state_sum, _steps, _ssteps)
                        # breakpoint()
                        next_states[rowcol] = (i, _steps, new_path_sum)
    current_states.clear()
    current_states.update(next_states)
    # print(next_states)
    # breakpoint()
    next_states.clear()
print(finished_value)


# CoordRowCol = tuple[int, int]
# IsDone = bool
# CurrentDirSteps = tuple[Dir | None, int]
# PathSum = int
# Path = list[CoordRowCol]

# State = tuple[CoordRowCol, CurrentDirSteps, PathSum]
# finished_value: int | float = float("inf")
# visited = set()
# opposite = {Dir.UP: Dir.DOWN, Dir.DOWN: Dir.UP, Dir.LEFT: Dir.RIGHT, Dir.RIGHT: Dir.LEFT}
# end_point = (MAX_ROW, MAX_COL)
# current_states: set[State] = {((1, 1), (None, 1), 0)}
# next_states: set[State] = set()
# while current_states:
#     for (row, col), (dir, steps), path_sum in current_states:
#         for i in Dir:
#             if dir is not None and i == opposite[dir]:
#                 continue
#             _row, _col = row, col
#             match i:
#                 case Dir.UP:
#                     _row -= 1
#                 case Dir.DOWN:
#                     _row += 1
#                 case Dir.LEFT:
#                     _col -= 1
#                 case Dir.RIGHT:
#                     _col += 1
#             index_value = raw_mat[_row][_col]
#             rowcol = (_row, _col)
#             if rowcol == end_point:
#                 finished_value = min(path_sum + index_value, finished_value)
#                 # print(finished_value)
#                 continue
#             if index_value:
#                 if dir == i:
#                     _steps = steps + 1
#                     if _steps >= 3:
#                         continue
#                 else:
#                     _steps = 0
#                     if dir is None:
#                         _steps += 1
#                 new_path_sum = path_sum + index_value
#                 if new_path_sum < finished_value:
#                     # if path == [(1, 2), (1, 3), (2, 3), (2, 4), (2, 5), (2, 6)]:  # (1,6)  23
#                     #     print(path_sum, index_value, repr(dir), repr(i))
#                     #     breakpoint()
#                     next_states.add((rowcol, (i, _steps), new_path_sum))
#     current_states.clear()
#     current_states.update(next_states)
#     next_states.clear()
# print(finished_value)


# from copy import deepcopy

# zeros = [list(x) for x in deepcopy(raw_mat)]
# for row, col in all_paths[-3]:
#     zeros[row][col] = 0
# for r in [x[1:-1] for x in zeros[1:-1]]:
#     print(r)
# print()

# for r in [x[1:-1] for x in raw_mat[1:-1]]:
#     print(r)


# 893 too low
# 897 too high
# 894 correct