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
use std::hash::Hash;

#[allow(dead_code)]
fn print<T: std::fmt::Debug>(x: T) {
    println!("{:?}", x);
}

type Point = (isize, isize, isize);
type PointF = (f64, f64, f64);

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
struct Nanobot {
    pos: Point,
    radius: isize,
}
impl Nanobot {
    fn manhattan(&self, o: &Nanobot) -> isize {
        manhattan(self.pos, o.pos)
    }
    fn overlaps_m(&self, o: &Nanobot) -> bool {
        let d = self.manhattan(o);
        d <= self.radius && d <= o.radius
    }
    fn overlaps(&self, o: &Nanobot) -> bool {
        self.manhattan(o) <= self.radius + o.radius
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

fn weighted_midpoint(nanobots: &Vec<&Nanobot>) -> Point {
    let mut total_weight = 0;
    let mut weighted_a_sum = 0;
    let mut weighted_b_sum = 0;
    let mut weighted_c_sum = 0;

    for bot in nanobots {
        let (a, b, c) = bot.pos;
        total_weight += bot.radius;
        weighted_a_sum += a * bot.radius;
        weighted_b_sum += b * bot.radius;
        weighted_c_sum += c * bot.radius;
    }
    let a = weighted_a_sum / total_weight;
    let b = weighted_b_sum / total_weight;
    let c = weighted_c_sum / total_weight;
    (a, b, c)
}

fn overlap_midpoint(a: Point, b: Point) -> Point {
    ((a.0 + b.0) / 2, (a.1 + b.1) / 2, (a.2 + b.2) / 2)
}

fn point_within(nanobot: &Nanobot, point: Point) -> bool {
    manhattan(nanobot.pos, point) <= nanobot.radius
}

fn manhattan(a: Point, b: Point) -> isize {
    let (a0, a1, a2) = a;
    let (b0, b1, b2) = b;
    (a0 - b0).abs() + (a1 - b1).abs() + (a2 - b2).abs()
}

fn part2(nanobots: &Vec<Nanobot>) {
    let mut visited_bots: HashSet<&Nanobot> = HashSet::new();
    let mut max_overlaps: usize = 0;
    for i in nanobots {
        if visited_bots.contains(&i) {
            continue;
        }
        let mut bots: Vec<&Nanobot> = vec![];
        for j in nanobots {
            if bots.iter().all(|b| b.overlaps(&j)) {
                bots.push(j);
            }
        }
        if bots.len() > max_overlaps {
            visited_bots.clear();
            max_overlaps = bots.len();
            visited_bots.extend(bots);
        }
    }
    let visited_bots = visited_bots;
    let mut bots: Vec<&Nanobot> = visited_bots.into_iter().collect();
    bots.sort_unstable_by_key(|b| b.radius);
    let bots = bots;

    let sum_manhattan = |pos| {
        bots.iter()
            .fold(0, |acc, bot| acc + manhattan(pos, bot.pos))
    };
    let mut pos = bots[0].pos;
    let mut minn: isize = 100000000000;
    for bot in &bots {
        // print(sum_manhattan(bot.pos))
        let m = sum_manhattan(bot.pos);
        if m < minn {
            pos = bot.pos;
            minn = m;
        }
    }
    let mut sum_dist = sum_manhattan(pos);
    loop {
        if bots.iter().all(|bot| point_within(bot, pos)) {
            print(pos);
            break;
        }
        const FACTOR: isize = 10;
        'outer: for i in -1..=1 {
            for j in -1..=1 {
                for k in -1..=1 {
                    let new_pos = (pos.0 + i * FACTOR, pos.1 + j * FACTOR, pos.2 + k * FACTOR);
                    let new_dist = sum_manhattan(new_pos);
                    if new_dist < sum_dist {
                        print(new_dist);
                        // print(new_pos);
                        sum_dist = new_dist;
                        pos = new_pos;
                        break 'outer;
                    }
                }
            }
        }
    }

    // for bot in &bots {
    //     let (a, b, c) = bot.pos;
    //     let r = bot.radius;
    //     for pa in a - r..=a + r {
    //         for pb in b - r..=b + r {
    //             for pc in c - r..=c + r {
    //                 // let (pa, pb, pc) = (pa * r + a, pb * r + b, pc * r + c);
    //                 if bots.iter().all(|b| point_within(b, (pa, pb, pc))) {
    //                     print((pa, pb, pc));
    //                     print("success");
    //                 }
    //             }
    //         }
    //     }
    //     break;
    // }

    // let (mut min_a, mut max_a) = (isize::MAX, isize::MIN);
    // let (mut min_b, mut max_b) = (isize::MAX, isize::MIN);
    // let (mut min_c, mut max_c) = (isize::MAX, isize::MIN);
    // for &bot in &bots {
    //     let (a, b, c) = bot.pos;
    //     let r = bot.radius;
    //     min_a = min_a.min(a - r);
    //     max_a = max_a.max(a + r);
    //     min_b = min_b.min(b - r);
    //     max_b = max_b.max(b + r);
    //     min_c = min_c.min(c - r);
    //     max_c = max_c.max(c + r);
    // }

    // 'outer: for a in min_a..=max_a {
    //     for b in min_b..=max_b {
    //         for c in min_c..=max_c {
    //             let point = (a, b, c);
    //             if bots.iter().all(|b| point_within(b, point)) {
    //                 print(point);
    //                 break 'outer;
    //             }
    //         }
    //     }
    // }

    // print(visited_bots);
}

fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d23.txt")?;
    let re = Regex::new(r"(-*\d+).(-*\d+).(-*\d+).+r=(\d+)").unwrap();

    let mut nanobots: Vec<Nanobot> = re
        .captures_iter(&content.trim_end())
        .map(|c| c.extract().1.map(|s| s.parse().unwrap()).into())
        .collect();
    nanobots.sort_unstable_by_key(|b| -b.radius);

    part2(&nanobots);

    // println!("Part 1: {}", part1(&nanobots));
    // println!("Part 2: {}", 2);
    Ok(())
}

fn part1(nanobots: &Vec<Nanobot>) -> usize {
    nanobots
        .iter()
        .filter(|r| nanobots[0].manhattan(r) <= nanobots[0].radius)
        .count()
}

// fn get_overlapping_edges(a: Nanobot, b: Nanobot) {
//     let mid_point = overlap_midpoint(a.pos, b.pos);
//     let mut edge_point: Point = mid_point;
//     loop {
//         // Walk right until border is found.
//         if a.radius < manhattan(a.pos, edge_point) {
//             break;
//         }
//         edge_point = (edge_point.0, edge_point.1 + 1)
//     }
// }

// fn part2(nanobots: &Vec<Nanobot>) {
//     let selfhattan = |(a, b, c): PointF| a.abs() + b.abs() + c.abs();
//     let manfloatan = |(a, b, c): PointF, (d, e, f): Point| {
//         (a - d as f64).abs() + (b - e as f64).abs() + (c - f as f64).abs()
//     };

//     // K means-ish. We have 1 cluster. Take first point as mean of each point as init guess.
//     // let best_points: Vec<PointF> = vec![];
//     let point @ (p0, p1, p2) = nanobots.iter().fold((0.0, 0.0, 0.0), |acc, bot| {
//         let (a, b, c) = bot.pos;
//         let (a0, a1, a2) = acc;
//         (a0 + a as f64, a1 + b as f64, a2 + c as f64)
//     });
//     let n_points = nanobots.len() as f64;
//     let centroid @ (c0, c1, c2) = (p0 / n_points, p1 / n_points, p2 / n_points);

//     let icentroid = (c0 as isize, c1 as isize, c2 as isize);

//     print(selfhattan(centroid));
// }
