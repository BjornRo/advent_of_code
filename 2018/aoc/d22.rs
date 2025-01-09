#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
#![allow(unused_must_use)]
use regex::Regex;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;

use RegionType::*;
type Pos = (isize, isize);
type Map = HashMap<Pos, isize>;

#[allow(dead_code)]
fn print<T: std::fmt::Debug>(x: T) {
    println!("{:?}", x);
}

#[derive(Debug)]
enum RegionType {
    Rocky,
    Wet,
    Narrow,
}

fn calc_geologic(pos: Pos, depth: isize, target: Pos, memo: &mut Map) -> isize {
    if let Some(&res) = memo.get(&pos) {
        return res;
    }
    let (row, col) = pos;
    let value = if pos == (0, 0) || pos == target {
        0
    } else if col == 0 {
        row * 16807
    } else if row == 0 {
        col * 48271
    } else {
        [(row - 1, col), (row, col - 1)]
            .iter()
            .map(|&pos| (calc_geologic(pos, depth, target, memo) + depth) % 20183)
            .fold(1, |acc, geologic| acc * geologic)
    };
    memo.insert(pos, value);
    value
}

fn calc_erosion(pos: Pos, depth: isize, target: Pos, memo: &mut Map) -> RegionType {
    let geo_idx = (calc_geologic(pos, depth, target, memo) + depth) % 20183;
    match geo_idx % 3 {
        0 => Rocky,
        1 => Wet,
        _2 => Narrow,
    }
}

fn region_value(region_type: RegionType) -> usize {
    match region_type {
        Rocky => 0,
        Wet => 1,
        Narrow => 2,
    }
}

fn part1(depth: isize, target @ (row, col): Pos, memo: &mut Map) -> usize {
    let mut sum: usize = 0;
    for (i, j) in (0..=row).flat_map(|i| (0..=col).map(move |j| (i, j))) {
        sum += region_value(calc_erosion((i, j), depth, target, memo));
    }
    sum
}

fn part2(depth: isize, target: Pos, memo: &Map) -> Option<u8> {
    //
    None
}

fn main() -> std::io::Result<()> {
    let (depth, target) = fs::read_to_string("in/d22t.txt")?
        .trim_end()
        .split_once("\n")
        .map(|(depth, target)| {
            let depth: isize = depth.split_once(" ").unwrap().1.parse().unwrap();
            let target: Pos = target
                .split_once(" ")
                .unwrap()
                .1
                .split_once(",")
                .map(|(row, col)| (row.parse().unwrap(), col.parse().unwrap()))
                .unwrap();
            (depth, target)
        })
        .unwrap();

    let mut memo: HashMap<Pos, isize> = HashMap::new();

    let p1 = part1(depth, target, &mut memo);
    print(p1);
    // print(&memo);
    let p2 = part2(depth, target, &memo);

    // println!("Part 1: {}", 1);
    // println!("Part 2: {}", 2);
    Ok(())
}
