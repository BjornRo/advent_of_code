use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap};
use std::fs;

use Equip::*;
use RegionType::*;
type Pos = (isize, isize);
type Map = HashMap<Pos, isize>;

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Clone, Copy)]
enum RegionType {
    Rocky,
    Wet,
    Narrow,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum Equip {
    Torch,
    Climb,
    Neither,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
struct Node {
    pos: Pos,
    equip: Equip,
    g_cost: usize,
    h_cost: usize,
}
impl Node {
    #[rustfmt::skip]
    fn new(pos: Pos, equip: Equip, g_cost: usize, h_cost: usize) -> Self {
        Node {pos, equip, g_cost, h_cost}
    }
    fn f_cost(&self) -> usize {
        self.g_cost + self.h_cost
    }
    fn get(&self) -> (Pos, Equip, usize) {
        (self.pos, self.equip, self.g_cost)
    }
}
impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f_cost().cmp(&self.f_cost())
    }
}
impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

fn calc_geologic(pos @ (row, col): Pos, depth: isize, target: Pos, memo: &mut Map) -> isize {
    if let Some(&res) = memo.get(&pos) {
        return res;
    }
    let value = if pos == (0, 0) || pos == target {
        0
    } else if row == 0 {
        col * 48271
    } else if col == 0 {
        row * 16807
    } else {
        let w = (calc_geologic((row - 1, col), depth, target, memo) + depth) % 20183;
        w * (calc_geologic((row, col - 1), depth, target, memo) + depth) % 20183
    };
    memo.insert(pos, value);
    value
}

fn erosion(pos: Pos, depth: isize, target: Pos, memo: &mut Map) -> RegionType {
    match (calc_geologic(pos, depth, target, memo) + depth) % 20183 % 3 {
        0 => Rocky,
        1 => Wet,
        _2 => Narrow,
    }
}

fn part1(depth: isize, target @ (row, col): Pos, memo: &mut Map) -> usize {
    let mut sum: usize = 0;
    for (i, j) in (0..=row).flat_map(|i| (0..=col).map(move |j| (i, j))) {
        sum += match erosion((i, j), depth, target, memo) {
            Rocky => 0,
            Wet => 1,
            Narrow => 2,
        };
    }
    sum
}

fn part2(depth: isize, target: Pos, memo: &mut Map) -> Option<usize> {
    const OFFSETS: [Pos; 5] = [(1, 0), (0, 1), (-1, 0), (0, -1), (0, 0)];
    let manhattan = |a: Pos, b: Pos| ((a.0 - b.0).abs() + (a.1 - b.1).abs()) as usize;
    let region_equip = |tile| match tile {
        Rocky => [Climb, Torch],
        Wet => [Climb, Neither],
        Narrow => [Torch, Neither],
    };

    let mut heap: BinaryHeap<Node> =
        vec![Node::new((0, 0), Torch, 0, manhattan((0, 0), target))].into();
    let mut g_costs: HashMap<(Pos, Equip), usize> = HashMap::new();

    while let Some((pos @ (row, col), equip, g_cost)) = heap.pop().map(|n| n.get()) {
        if pos == target && equip == Torch {
            return Some(g_cost);
        }

        for (dr, dc) in OFFSETS {
            let np @ (nr, nc) = (row + dr, col + dc);
            if nr < 0 || nc < 0 {
                continue;
            }
            let (mut new_equip, mut new_g_cost) = (equip, g_cost);
            if pos == np {
                new_g_cost += 7;
                new_equip = *region_equip(erosion(pos, depth, target, memo))
                    .iter()
                    .filter(|&&next_equip| next_equip != equip)
                    .next()
                    .unwrap();
            } else {
                if !region_equip(erosion(np, depth, target, memo)).contains(&new_equip) {
                    continue;
                }
                new_g_cost += 1;
            }

            if let Some(&existing_g_cost) = g_costs.get(&(np, new_equip)) {
                if new_g_cost >= existing_g_cost {
                    continue;
                }
            }
            g_costs.insert((np, new_equip), new_g_cost);
            heap.push(Node::new(np, new_equip, new_g_cost, manhattan(np, target)));
        }
    }
    None
}

fn main() -> std::io::Result<()> {
    let (depth, target) = fs::read_to_string("in/d22.txt")?
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
    let p2 = part2(depth, target, &mut memo).unwrap();
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
