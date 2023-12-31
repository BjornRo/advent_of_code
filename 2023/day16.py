from time import perf_counter as time_it

start_it = time_it()

from enum import IntEnum
from typing import Literal


class Dir(IntEnum):
    UP = 1
    DOWN = 2
    LEFT = 4
    RIGHT = 8


CoordsROWCOL = tuple[int, int]
Streaks = tuple[Dir, CoordsROWCOL]


def lawn_mover(dir: Dir, pos: CoordsROWCOL, ditch_row: int, ditch_col: int) -> Literal[0] | CoordsROWCOL:
    row, col = pos
    match dir:
        case Dir.UP:
            row -= 1
        case Dir.DOWN:
            row += 1
        case Dir.LEFT:
            col -= 1
        case Dir.RIGHT:
            col += 1
    if 0 <= row < ditch_row and 0 <= col < ditch_col:
        return row, col
    return 0


def lawn_shapes(lawn: list[str], ditch_row: int, ditch_col: int, dir: Dir, start: CoordsROWCOL, skip: bool):
    drunk_lawn = [[0 for _ in range(ditch_col)] for _ in range(ditch_row)]
    basket: list[Streaks] = [(dir, start)]
    while basket:
        dir, (row, col) = basket.pop()
        if not drunk_lawn[row][col] & dir:
            drunk_lawn[row][col] |= dir
            if not skip:
                match lawn[row][col]:
                    case "/" | "\\" as angle:
                        if angle == "/":
                            mapping = {Dir.RIGHT: Dir.UP, Dir.UP: Dir.RIGHT, Dir.DOWN: Dir.LEFT, Dir.LEFT: Dir.DOWN}
                        else:
                            mapping = {Dir.RIGHT: Dir.DOWN, Dir.DOWN: Dir.RIGHT, Dir.UP: Dir.LEFT, Dir.LEFT: Dir.UP}
                        new_dir = mapping[dir]
                        if next_patch := lawn_mover(new_dir, (row, col), ditch_col, ditch_row):
                            basket.append((new_dir, next_patch))
                        continue
                    case "-" | "|" as pole:
                        dirs = (Dir.LEFT, Dir.RIGHT) if pole == "-" else (Dir.UP, Dir.DOWN)
                        if dir not in dirs:
                            for d in dirs:
                                if next_patch := lawn_mover(d, (row, col), ditch_col, ditch_row):
                                    basket.append((d, next_patch))
                            continue
            if next_patch := lawn_mover(dir, (row, col), ditch_col, ditch_row):
                basket.append((dir, next_patch))
                skip = False
    return sum(bool(c) for r in drunk_lawn for c in r)


def lawn_starter(row: int, col: int) -> set[tuple[Dir, CoordsROWCOL]]:
    _col, drunk_coords = col - 1, set()
    for i in range(col):
        drunk_coords.add((Dir.DOWN, (0, i)))
        if i != 0:
            drunk_coords.add((Dir.LEFT, (0, i)))
        if i != _col:
            drunk_coords.add((Dir.RIGHT, (0, i)))
        drunk_coords.add((Dir.UP, (_col, i)))
        if i != 0:
            drunk_coords.add((Dir.LEFT, (_col, i)))
        if i != _col:
            drunk_coords.add((Dir.RIGHT, (_col, i)))
    for i in range(1, row - 2):
        drunk_coords.add((Dir.RIGHT, (i, 0)))
        drunk_coords.add((Dir.LEFT, (i, _col)))
    return drunk_coords


with open("in/d16.txt") as f:
    lawn = [x.rstrip() for x in f.readlines()]
DITCH_ROW, DITCH_COL = len(lawn), len(lawn[0])
print("Part 1:", lawn_shapes(lawn, DITCH_ROW, DITCH_COL, Dir.RIGHT, (0, 0), False))
print("Part 2:", max((lawn_shapes(lawn, DITCH_ROW, DITCH_COL, *x, True) for x in lawn_starter(DITCH_ROW, DITCH_COL))))
print("Finished in:", round(time_it() - start_it, 4), "secs")
