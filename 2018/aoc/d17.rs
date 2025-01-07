#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
use regex::Regex;
use std::cmp::{max, min};
use std::collections::HashSet;
use std::{collections::HashMap, collections::VecDeque, fs};

// ALL VALUES IN RANGES ARE INCLUSIVE!
type Range = (usize, usize);
type Position = (i16, i16);

#[derive(Debug, Clone)]
struct ClayRanges {
    rows: Range,
    cols: Range,
}

#[derive(Debug, Clone)]
enum WaterState {
    FILL,
    FLOW,
}

#[derive(Debug, Clone)]
struct State {
    pos: (i16, i16),
    state: WaterState,
}

fn part1(clay_ranges: &Vec<ClayRanges>, max_cols: usize, max_rows: usize, well_col: usize) {
    let mut grid = vec![vec!['.'; max_cols + 3]; max_rows + 1];
    // println!("{:?}", clay_ranges);
    // println!("{} {} {}", max_cols, max_rows, well_col);

    grid[0][well_col] = '+';
    for range in clay_ranges {
        let (ra, rb) = range.rows;
        let (ca, cb) = range.cols;
        for i in ra..=rb {
            for j in ca..=cb {
                grid[i][j] = '#';
            }
        }
    }

    waterfall(&mut grid, well_col);

    for r in grid {
        let row_str: String = r.into_iter().collect();
        println!("{}", row_str);
    }
}

fn waterfall(grid: &mut Vec<Vec<char>>, start_col: usize) {
    use self::WaterState::*;
    let mut queue: VecDeque<State> = vec![State {
        pos: (1, start_col as i16),
        state: FLOW,
    }]
    .into();

    let mut water_spots: HashSet<(i16, i16)> = HashSet::new();

    while !queue.is_empty() {
        let current = queue.pop_front().unwrap();
        let pos @ (row, col) = current.pos;

        water_spots.insert(current.pos);

        if matches!(current.state, FLOW) {
            grid[row as usize][col as usize] = '|';
            let np @ (nr, nc) = (row + 1, col);
            if nr >= grid.len() as i16 {
                continue;
            }
            let next_state = if grid[nr as usize][nc as usize] == '#' {
                State { pos, state: FILL }
            } else {
                State {
                    pos: np,
                    state: FLOW,
                }
            };
            queue.push_back(next_state);
        } else {
            // grid[row as usize][col as usize] = '~';
            let mut overflowed = false;
            // check left side
            let mut left_pos = pos;
            loop {
                let np @ (nr, nc) = (left_pos.0, left_pos.1 - 1);
                if grid[nr as usize][nc as usize] == '#' {
                    break;
                }
                if grid[(nr + 1) as usize][nc as usize] == '.' {
                    queue.push_back(State {
                        pos: np,
                        state: FLOW,
                    });
                    overflowed = true;
                    break;
                }
                left_pos = np;
            }
            let mut right_pos = pos;
            loop {
                let np @ (nr, nc) = (right_pos.0, right_pos.1 + 1);
                if grid[nr as usize][nc as usize] == '#' {
                    break;
                }
                if grid[(nr + 1) as usize][nc as usize] == '.' {
                    queue.push_back(State {
                        pos: np,
                        state: FLOW,
                    });
                    overflowed = true;
                    break;
                }
                right_pos = np;
            }
            let c = if overflowed { '|' } else { '~' };
            grid[row as usize][left_pos.1 as usize..=right_pos.1 as usize]
                .iter_mut()
                .enumerate()
                .for_each(|(i, elem)| {
                    *elem = c;
                    water_spots.insert((row, i as i16 + left_pos.1));
                });
            if !overflowed {
                queue.push_back(State {
                    pos: (row - 1, col),
                    state: FILL,
                });
            }
            // if overflowed {
            //     println!("{:?}", queue);
            //     break;
            // }
        }
    }
    println!("{}", water_spots.len());
}

fn main() -> std::io::Result<()> {
    let mut min_cols: usize = !0;
    let mut max_cols: usize = 0;
    let mut max_rows: usize = 0;

    let clay_ranges: Vec<ClayRanges> = fs::read_to_string("in/d17t.txt")?
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

            let result @ (rows, cols) = match left_var {
                "y" => (left_range, right_range),
                _ => (right_range, left_range),
            };
            result
        })
        .inspect(|&((ra, rb), (ca, cb))| {
            min_cols = min(min_cols, ca);
            max_cols = max(max_cols, cb);
            max_rows = max(max(max_rows, ra), rb);
        })
        .collect::<Vec<(Range, Range)>>()
        .iter()
        .map(|&(rows, (a, b))| ClayRanges {
            rows,
            cols: (a - min_cols + 1, b - min_cols + 1),
        })
        .collect();

    part1(&clay_ranges, max_cols - min_cols, max_rows, 500 - min_cols);

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
