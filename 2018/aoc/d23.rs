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

type Point = (isize, isize, isize);
type PointF = (f64, f64, f64);

#[derive(Debug, Clone, Eq, PartialEq)]
struct Nanobot {
    pos: Point,
    radius: isize,
}
impl Nanobot {
    fn manhattan(&self, o: &Nanobot) -> isize {
        let (a0, a1, a2) = self.pos;
        let (b0, b1, b2) = o.pos;
        (a0 - b0).abs() + (a1 - b1).abs() + (a2 - b2).abs()
    }
}
impl Ord for Nanobot {
    fn cmp(&self, other: &Self) -> Ordering {
        other.radius.cmp(&self.radius)
    }
}
impl PartialOrd for Nanobot {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
impl From<[isize; 4]> for Nanobot {
    fn from(i: [isize; 4]) -> Self {
        let [a, b, c, d] = i;
        Nanobot {
            pos: (a, b, c),
            radius: d,
        }
    }
}

fn part1(nanobots: &Vec<Nanobot>) -> usize {
    nanobots
        .iter()
        .filter(|r| nanobots[0].manhattan(r) <= nanobots[0].radius)
        .count()
}

fn part2(nanobots: &Vec<Nanobot>) {
    let selfhattan = |(a, b, c): PointF| a.abs() + b.abs() + c.abs();
    let manfloatan = |(a, b, c): PointF, (d, e, f): Point| {
        (a - d as f64).abs() + (b - e as f64).abs() + (c - f as f64).abs()
    };

    // K means-ish. We have 1 cluster. Take first point as mean of each point as init guess.
    // let best_points: Vec<PointF> = vec![];
    let point @ (p0, p1, p2) = nanobots.iter().fold((0.0, 0.0, 0.0), |acc, bot| {
        let (a, b, c) = bot.pos;
        let (a0, a1, a2) = acc;
        (a0 + a as f64, a1 + b as f64, a2 + c as f64)
    });
    let n_points = nanobots.len() as f64;
    let centroid @ (c0, c1, c2) = (p0 / n_points, p1 / n_points, p2 / n_points);

    let icentroid = (c0 as isize, c1 as isize, c2 as isize);

    print(selfhattan(centroid));
}

fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d23tt.txt")?;
    let re = Regex::new(r"(-*\d+).(-*\d+).(-*\d+).+r=(\d+)").unwrap();

    let mut nanobots: Vec<Nanobot> = re
        .captures_iter(&content.trim_end())
        .map(|c| c.extract().1.map(|s| s.parse().unwrap()).into())
        .collect();
    nanobots.sort_unstable();

    part2(&nanobots);

    // println!("Part 1: {}", part1(&nanobots));
    // println!("Part 2: {}", 2);
    Ok(())
}
