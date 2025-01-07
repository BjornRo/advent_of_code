#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

// [from,to], inclusive range
type Range = [usize; 2];

#[derive(Debug, Clone)]
#[allow(dead_code)]
struct ClayRanges {
    rows: Range,
    cols: Range,
}

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let all_ranges: Vec<ClayRanges> = fs::read_to_string("in/d17t.txt")?
        .trim_end()
        .lines()
        .map(|line| {
            let (left, right) = line.split_once(", ").unwrap();

            let (left_var, left_val) = left.split_once("=").unwrap();
            let (_, right_val) = right.split_once("=").unwrap();

            let left_range: Range = [left_val.parse().unwrap(); 2];
            let right_range: Range = right_val
                .split_once("..")
                .map(|(l, r)| [l.parse().unwrap(), r.parse().unwrap()])
                .unwrap();

            let (rows, cols) = match left_var {
                "y" => (left_range, right_range),
                _ => (right_range, left_range),
            };
            ClayRanges { rows, cols }
        })
        .collect();

    println!("{:?}", all_ranges);

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
