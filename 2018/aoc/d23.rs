#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
#![allow(unused_must_use)]
use regex::Regex;
use std::cmp::Ordering;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;

#[allow(dead_code)]
fn print<T: std::fmt::Debug>(x: T) {
    println!("{:?}", x);
}

#[derive(Debug, Clone, Eq, PartialEq)]
struct Point {
    pos: (isize, isize, isize),
    radius: isize,
}
impl Point {
    fn manhattan(&self, o: &Point) -> isize {
        let (a0, a1, a2) = self.pos;
        let (b0, b1, b2) = o.pos;
        (a0 - b0).abs() + (a1 - b1).abs() + (a2 - b2).abs()
    }
}
impl Ord for Point {
    fn cmp(&self, other: &Self) -> Ordering {
        other.radius.cmp(&self.radius)
    }
}
impl PartialOrd for Point {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl From<[isize; 4]> for Point {
    fn from(i: [isize; 4]) -> Self {
        let [a, b, c, d] = i;
        Point {
            pos: (a, b, c),
            radius: d,
        }
    }
}

fn part1(points: &Vec<Point>) -> usize {
    points
        .iter()
        .filter(|r| points[0].manhattan(r) <= points[0].radius)
        .count()
}

fn part2(points: &Vec<Point>) {
    //
}

fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d23tt.txt")?;
    let re = Regex::new(r"(-*\d+).(-*\d+).(-*\d+).+r=(\d+)").unwrap();

    let mut points: Vec<Point> = re
        .captures_iter(&content.trim_end())
        .map(|c| c.extract().1.map(|s| s.parse().unwrap()).into())
        .collect();
    points.sort_unstable();

    part2(&points);

    // println!("Part 1: {}", part1(&points));
    // println!("Part 2: {}", 2);
    Ok(())
}
