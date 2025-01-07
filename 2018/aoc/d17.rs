use std::cmp::{max, min};
use std::{collections::VecDeque, fs};

type Range = (usize, usize);
type Position = Range;

struct ClayRanges {
    rows: Range,
    cols: Range,
}

enum WaterState {
    FILL,
    FLOW,
}

struct State {
    pos: Position,
    state: WaterState,
}

impl State {
    fn new(pos: Position, state: WaterState) -> Self {
        State { pos, state }
    }
}

fn solver(clay_ranges: &Vec<ClayRanges>, cols: usize, rows: usize, well: usize) -> (usize, usize) {
    let mut grid = vec![vec!['.'; cols + 3]; rows + 1];
    grid[0][well] = '+';
    for range in clay_ranges {
        (range.rows.0..=range.rows.1)
            .flat_map(|i| (range.cols.0..=range.cols.1).map(move |j| (i, j)))
            .for_each(|(i, j)| grid[i][j] = '#');
    }
    waterfall(&mut grid, well);
    grid.iter()
        .flat_map(|row| row.iter())
        .fold((0, 0), |(flow, fill), &cell| match cell {
            '~' => (flow, fill + 1),
            '|' => (flow + 1, fill),
            _ => (flow, fill),
        })
}

fn waterfall(grid: &mut Vec<Vec<char>>, start_col: usize) {
    fn fill_up(grid: &Vec<Vec<char>>, mut pos: Position, dir: i16) -> (Option<State>, Position) {
        loop {
            let next_pos @ (nr, nc) = (pos.0, (pos.1 as i16 + dir) as usize);
            if grid[nr][nc] == '#' {
                return (None, pos);
            }
            if ['.', '|'].contains(&grid[nr + 1][nc]) {
                return (Some(State::new(next_pos, FLOW)), pos);
            }
            pos = next_pos;
        }
    }
    use self::WaterState::*;
    let mut queue: VecDeque<State> = vec![State::new((1, start_col), FLOW)].into();
    while let Some(current) = queue.pop_front() {
        let pos @ (row, col) = current.pos;

        if matches!(current.state, FLOW) {
            if grid[row][col] != '|' {
                grid[row][col] = '|';
                let np @ (nr, nc) = (row + 1, col);
                if nr < grid.len() && grid[nr][nc] != '|' {
                    queue.push_back(if grid[nr][nc] == '.' {
                        State::new(np, FLOW)
                    } else {
                        State::new(pos, FILL)
                    });
                }
            }
        } else {
            let mut overflowed = false;
            let (next_state_l, left_pos) = fill_up(grid, pos, -1);
            let (next_state_r, right_pos) = fill_up(grid, pos, 1);
            for st in [next_state_l, next_state_r] {
                if let Some(next_state) = st {
                    queue.push_back(next_state);
                    overflowed = true;
                }
            }

            let c = if overflowed {
                '|'
            } else {
                queue.push_back(State::new((row - 1, col), FILL));
                '~'
            };
            grid[row][left_pos.1..=right_pos.1]
                .iter_mut()
                .for_each(|elem| *elem = c);
        }
    }
}

fn main() -> std::io::Result<()> {
    let (mut min_cols, mut max_cols): Position = (!0, 0);
    let (mut min_rows, mut max_rows): Position = (!0, 0);

    let clay_ranges: Vec<ClayRanges> = fs::read_to_string("in/d17.txt")?
        .trim_end()
        .lines()
        .map(|line| {
            let (left, right) = line.split_once(", ").unwrap();

            let (left_var, left_val) = left.split_once("=").unwrap();
            let (_, right_val) = right.split_once("=").unwrap();

            let left_range: Range = (left_val.parse().unwrap(), left_val.parse().unwrap());
            let right_range: Range = right_val
                .split_once("..")
                .map(|(l, r)| (l.parse().unwrap(), r.parse().unwrap()))
                .unwrap();

            match left_var {
                "y" => (left_range, right_range),
                _ => (right_range, left_range),
            }
        })
        .inspect(|&((ra, rb), (ca, cb))| {
            min_cols = min(min_cols, ca);
            max_cols = max(max_cols, cb);
            min_rows = min(min_rows, ra);
            max_rows = max(max_rows, rb);
        })
        .collect::<Vec<(Range, Range)>>()
        .iter()
        .map(|&((ra, rb), (ca, cb))| ClayRanges {
            rows: (ra - min_rows + 1, rb - min_rows + 1),
            cols: (ca - min_cols + 1, cb - min_cols + 1),
        })
        .collect();

    let (flow, fill) = solver(
        &clay_ranges,
        max_cols - min_cols,
        max_rows - min_rows + 1,
        500 - min_cols + 1,
    );
    println!("Part 1: {}", flow + fill);
    println!("Part 2: {}", fill);
    Ok(())
}
