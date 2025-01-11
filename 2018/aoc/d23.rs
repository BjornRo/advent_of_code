use regex::Regex;
use std::collections::HashSet;
use std::hash::Hash;
use std::{fs, isize};

type Point = (isize, isize, isize);

#[derive(Debug, Eq, PartialEq, Hash)]
struct Nanobot {
    pos: Point,
    radius: isize,
}
impl From<[isize; 4]> for Nanobot {
    fn from(i: [isize; 4]) -> Self {
        let [a, b, c, radius] = i;
        let pos = (a, b, c);
        Nanobot { pos, radius }
    }
}

fn manhattan(a: Point, b: Point) -> isize {
    let (a0, a1, a2) = a;
    let (b0, b1, b2) = b;
    (a0 - b0).abs() + (a1 - b1).abs() + (a2 - b2).abs()
}

fn sq_sum_manhattan_radius(list: &Vec<&Nanobot>, pos: Point) -> isize {
    list.iter().fold(0, |acc, bot| {
        let m = manhattan(pos, bot.pos);
        let radius_penalty = bot.radius - m;
        acc + m * m + radius_penalty * radius_penalty
    })
}

fn find_overlap_range(bots: &Vec<&Nanobot>) -> [(isize, isize); 3] {
    let ((a, b, c), r) = (bots[0].pos, bots[0].radius);
    let (mut min_a, mut max_a) = (a - r, a + r);
    let (mut min_b, mut max_b) = (b - r, b + r);
    let (mut min_c, mut max_c) = (c - r, c + r);

    for bot in bots.iter().skip(1) {
        let ((a, b, c), r) = (bot.pos, bot.radius);
        (min_a, max_a) = (min_a.max(a - r), max_a.min(a + r));
        (min_b, max_b) = (min_b.max(b - r), max_b.min(b + r));
        (min_c, max_c) = (min_c.max(c - r), max_c.min(c + r));
    }

    [(min_a, max_a), (min_b, max_b), (min_c, max_c)]
}

fn part1(nanobots: &Vec<Nanobot>) -> usize {
    nanobots
        .iter()
        .filter(|o| manhattan(nanobots[0].pos, o.pos) <= nanobots[0].radius)
        .count()
}

fn part2(nanobots: &Vec<Nanobot>) -> usize {
    let bots: Vec<&Nanobot> = {
        // Find the set with the most overlaps, use visited to reduce comparisons
        let overlaps = |a: &Nanobot, b: &Nanobot| manhattan(a.pos, b.pos) <= (a.radius + b.radius);
        let mut visited_bots: HashSet<&Nanobot> = HashSet::new();
        for i in nanobots {
            if visited_bots.contains(&i) {
                continue;
            }
            let bots: Vec<&Nanobot> = nanobots.iter().fold(vec![], |mut acc, j| {
                if acc.iter().all(|&b| overlaps(b, j)) {
                    acc.push(j);
                }
                acc
            });
            if bots.len() > visited_bots.len() {
                visited_bots = bots.into_iter().collect();
            }
        }
        visited_bots.drain().collect()
    };

    // Generate sets for the gradient descent to minimize into.
    // bots_not_overlap is our target for gradient descent.
    // Then if we find an overlap, repartition again.
    let point_within = |b: &Nanobot, point: Point| manhattan(b.pos, point) <= b.radius;
    let partition = |p: Point| -> (Vec<&Nanobot>, Vec<&Nanobot>) {
        bots.iter().partition(|bot| point_within(bot, p))
    };

    // Get the ranges that all spheres overlap to reduce search space.
    // Then get the midpoint of the valid ranges
    let mut pos: Point = find_overlap_range(&bots)
        .map(|p| (p.0 + p.1) / 2)
        .try_into()
        .unwrap();
    let (mut bots_overlap, mut bots_not_overlap) = partition(pos);
    let mut min_sum: isize = isize::MAX;
    let mut visit: HashSet<Point> = HashSet::new();
    let mut factor: isize = 1 << 20; // Adjust to terminate. 49 loops for my input (instant)
    loop {
        if bots.len() == bots_overlap.len() && !visit.insert(pos) {
            break;
        }

        let mut best_score = min_sum;
        let mut best_pos = pos;
        for i in -1..=1 {
            for j in -1..=1 {
                for k in -1..=1 {
                    if i == 0 && j == 0 && k == 0 {
                        continue;
                    }
                    let new_pos = (pos.0 + i * factor, pos.1 + j * factor, pos.2 + k * factor);
                    let new_dist = sq_sum_manhattan_radius(&bots_not_overlap, new_pos);
                    if new_dist < min_sum || bots.len() == bots_overlap.len() {
                        let new_overlaps =
                            bots.iter().filter(|bot| point_within(bot, new_pos)).count();
                        if new_overlaps > bots_overlap.len() {
                            (bots_overlap, bots_not_overlap) = partition(new_pos);
                        }
                        if new_overlaps >= bots_overlap.len() && best_score > new_dist {
                            (best_score, best_pos) = (new_dist, new_pos);
                        }
                    }
                }
            }
        }
        if best_score >= min_sum {
            if factor > 1 {
                factor /= 2;
            } else {
                factor = 1;
            }
        }
        min_sum = best_score;
        pos = best_pos;
    }
    visit
        .iter()
        .map(|p| manhattan(*p, (0, 0, 0)))
        .min()
        .unwrap() as usize
}

fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d23.txt")?;
    let re = Regex::new(r"(-*\d+).(-*\d+).(-*\d+).+r=(\d+)").unwrap();

    let mut nanobots: Vec<Nanobot> = re
        .captures_iter(&content.trim_end())
        .map(|c| c.extract().1.map(|s| s.parse().unwrap()).into())
        .collect();
    nanobots.sort_unstable_by_key(|b| -b.radius);

    println!("Part 1: {}", part1(&nanobots));
    println!("Part 2: {}", part2(&nanobots));
    Ok(())
}
