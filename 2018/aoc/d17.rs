#[allow(unused_imports)]
use regex::Regex;
use std::cmp::{max, min};
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

// ALL VALUES IN RANGES ARE INCLUSIVE!
type Range = (usize, usize);

#[derive(Debug, Clone)]
#[allow(dead_code)]
struct ClayRanges {
    rows: Range,
    cols: Range,
}

#[allow(dead_code)]
fn part1(clay_ranges: &Vec<ClayRanges>, max_cols: usize, max_rows: usize, well_col: usize) {
    let mut grid = vec![vec!['.'; max_cols + 1]; max_rows + 1];
    // println!("{:?}", clay_ranges);
    println!("{} {} {}", max_cols, max_rows, well_col);

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

    for r in grid {
        let row_str: String = r.into_iter().collect();
        println!("{}", row_str);
    }
}

#[allow(unused_mut)]
#[allow(unused_variables)]
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
            cols: (a - min_cols, b - min_cols),
        })
        .collect();

    part1(&clay_ranges, max_cols - min_cols, max_rows, 500 - min_cols);

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
