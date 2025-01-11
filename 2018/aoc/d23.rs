use regex::Regex;
use std::collections::HashSet;
use std::hash::Hash;
use std::{fs, isize};

#[allow(dead_code)]
fn print<T: std::fmt::Debug>(x: T) {
    println!("{:?}", x);
}

type Point = (isize, isize, isize);

#[derive(Debug, Clone, Eq, PartialEq, Hash)]
struct Nanobot {
    pos: Point,
    radius: isize,
}
impl Nanobot {
    fn overlaps(&self, o: &Nanobot) -> bool {
        manhattan(self.pos, o.pos) <= (self.radius + o.radius)
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
fn manhattan(a: Point, b: Point) -> isize {
    let (a0, a1, a2) = a;
    let (b0, b1, b2) = b;
    (a0 - b0).abs() + (a1 - b1).abs() + (a2 - b2).abs()
}

fn part1(nanobots: &Vec<Nanobot>) -> usize {
    nanobots
        .iter()
        .filter(|o| manhattan(nanobots[0].pos, o.pos) <= nanobots[0].radius)
        .count()
}

fn point_within(nanobot: &Nanobot, point: Point) -> bool {
    manhattan(nanobot.pos, point) <= nanobot.radius
}

fn count_overlaps(list: &Vec<&Nanobot>, pos: Point) -> usize {
    list.iter().filter(|bot| point_within(bot, pos)).count()
}

fn sq_sum_manhattan_radius(list: &Vec<&Nanobot>, pos: Point) -> isize {
    list.iter().fold(0, |acc, bot| {
        let m = manhattan(pos, bot.pos);
        let radius_penalty = bot.radius - m;
        acc + m * m + radius_penalty * radius_penalty
    })
}

fn find_overlap_range(bots: &Vec<&Nanobot>) -> ((isize, isize), (isize, isize), (isize, isize)) {
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

    ((min_a, max_a), (min_b, max_b), (min_c, max_c))
}

fn part2(nanobots: &Vec<Nanobot>) -> isize {
    // Find the set with the most overlaps, use visited to reduce comparisons
    // goal (18090900, 53369449, 57983828) = 978 overlaps. This function takes sooo
    // long time.
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
    let bots: Vec<&Nanobot> = visited_bots.into_iter().collect();

    // Get the ranges that all spheres overlap to reduce search space.
    #[allow(unused_variables)]
    let (a @ (min_a, max_a), b @ (min_b, max_b), c @ (min_c, max_c)) = find_overlap_range(&bots);
    let mid = |p: (isize, isize)| (p.0 + p.1) / 2;
    let mut pos = (mid(a), mid(b), mid(c));

    // Generate sets for the gradient descent to minimize into.
    // bots_not_overlap is our target for gradient descent.
    // Then if we find an overlap, repartition again.
    let partition = |p: Point| -> (Vec<&Nanobot>, Vec<&Nanobot>) {
        bots.iter().partition(|bot| point_within(bot, p))
    };

    let (mut bots_overlap, mut bots_not_overlap) = partition(pos);
    let mut min_sum: isize = isize::MAX;
    let mut visit: HashSet<Point> = HashSet::new();
    loop {
        if bots.len() == bots_overlap.len() {
            if visit.contains(&pos) {
                return visit
                    .iter()
                    .map(|p| manhattan(*p, (0, 0, 0)))
                    .min()
                    .unwrap();
            }
            visit.insert(pos);
        }

        let mut best_score = min_sum;
        let mut best_pos = pos;
        for i in -1..=1 {
            for j in -1..=1 {
                for k in -1..=1 {
                    if i == 0 && j == 0 && k == 0 {
                        continue;
                    }
                    let new_pos = (pos.0 + i, pos.1 + j, pos.2 + k);
                    let new_dist = sq_sum_manhattan_radius(&bots_not_overlap, new_pos);
                    if new_dist < min_sum || bots.len() == bots_overlap.len() {
                        let new_overlaps = count_overlaps(&bots, new_pos);
                        if new_overlaps > bots_overlap.len() {
                            (bots_overlap, bots_not_overlap) = partition(new_pos);
                        }
                        if new_overlaps >= bots_overlap.len() {
                            if best_score > new_dist {
                                best_score = new_dist;
                                best_pos = new_pos;
                            }
                        }
                    }
                }
            }
        }
        min_sum = best_score;
        pos = best_pos;
    }
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
