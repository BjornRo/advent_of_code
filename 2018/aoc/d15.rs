#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::cmp::Ordering;
#[allow(unused_imports)]
use std::collections::{BinaryHeap, HashMap, HashSet};
#[allow(unused_imports)]
use std::fs;

type Position = (i8, i8);
const OFFSETS: [Position; 4] = [(1, 0), (0, 1), (-1, 0), (0, -1)];

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
struct Node {
    position: Position,
    g_cost: u8,
    h_cost: u8,
}
impl Node {
    fn f_cost(&self) -> u8 {
        self.g_cost + self.h_cost
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

#[derive(Clone, PartialEq, Debug)]
enum UnitType {
    GOBLIN,
    ELF,
}

#[derive(Clone, Debug)]
#[allow(dead_code)]
struct Unit {
    id: u8,
    r#type: UnitType,
    hp: i16,
    attack: i16,
    position: Position,
}

impl Unit {
    fn new(id: u8, r#type: UnitType, position: Position) -> Self {
        Unit {
            id,
            r#type,
            hp: 200,
            attack: 3,
            position,
        }
    }
    fn alive(&self) -> bool {
        self.hp > 0
    }
}

fn part1(mut units: Vec<Unit>, grid: &Vec<Vec<bool>>) {
    loop {
        units.sort_unstable_by_key(|u| (u.position.0, u.position.1));

        for i in 0..units.len() {
            let unit = units[i].clone();
            if !unit.alive() {
                continue;
            }

            let unit_positions: HashSet<Position> = units.iter().map(|u| u.position).collect();
            let mut targets: Vec<&mut Unit> = units
                .iter_mut()
                .filter(|o| o.r#type != unit.r#type && o.alive())
                .collect();
            if targets.len() == 0 {
                println!("{:?}", units);
                println!("{:?} wins", unit.r#type);
                return;
            }

            let end_positions: Vec<(Position, u8)> = targets
                .iter()
                .enumerate()
                .flat_map(|(j, o)| {
                    let unit_positions = &unit_positions;
                    OFFSETS.iter().filter_map(move |(dr, dc)| {
                        let np @ (row, col) = (o.position.0 - dr, o.position.1 - dc);
                        if unit.position == np {
                            return Some((np, j as u8));
                        }
                        if !grid[row as usize][col as usize] || unit_positions.contains(&np) {
                            None
                        } else {
                            Some((np, j as u8))
                        }
                    })
                })
                .collect();

            let attackable_targets: Vec<u8> = end_positions
                .iter()
                .filter(|&&(pos, _)| pos == unit.position)
                .map(|&(_, uid)| uid)
                .collect();

            if attackable_targets.len() >= 1 {
                let target = attackable_targets
                    .iter()
                    .min_by_key(|&&i| {
                        (
                            targets[i as usize].hp,
                            targets[i as usize].position.0,
                            targets[i as usize].position.0,
                        )
                    })
                    .unwrap();
                targets[*target as usize].hp -= unit.attack;
            } else {
                let mut paths: Vec<_> = end_positions
                    .iter()
                    .filter_map(|&(end_pos, _)| {
                        a_star(units[i].position, end_pos, grid, &unit_positions)
                    })
                    .collect();
                if paths.len() >= 1 {
                    paths.sort_unstable_by_key(|&(v, (dr, _))| (v, dr));
                    units[i].position.0 += paths[0].1 .0;
                    units[i].position.1 += paths[0].1 .1;
                    if unit.r#type == UnitType::ELF {
                        // println!("{:?}", unit);
                        // println!("{:?}", targets);
                        println!("{:?}", paths);
                        // println!("{:?}", units[i]);
                        for i in units.clone() {
                            println!("{:?}", i);
                        }
                    }
                    // println!("{:?}", paths);
                    // println!("{:?}", units[i]);
                }
            }

            // return;
        }
    }
    //
}

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let mut matrix: Vec<Vec<char>> = fs::read_to_string("in/d15t.txt")?
        .trim_end()
        .split("\n")
        .map(|row| row.chars().collect())
        .collect();

    let mut units: Vec<Unit> = vec![];

    let mut id: u8 = 0;
    for i in 0..matrix.len() {
        for j in 0..matrix[0].len() {
            if let Some(r#type) = match matrix[i][j] {
                'G' => Some(UnitType::GOBLIN),
                'E' => Some(UnitType::ELF),
                _ => None,
            } {
                matrix[i][j] = '.';
                units.push(Unit::new(id, r#type, (i as i8, j as i8)));
                id += 1;
            }
        }
    }

    let mut matrix_bool: Vec<Vec<bool>> = matrix
        .iter()
        .map(|row| row.into_iter().map(|&c| c == '.').collect())
        .collect();

    part1(units.clone(), &matrix_bool);

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}

#[allow(dead_code)]
fn a_star(
    start: Position,
    target: Position,
    grid: &Vec<Vec<bool>>,
    unit_positions: &HashSet<Position>,
) -> Option<(u8, Position)> {
    // Option<(u8, Vec<Position>)>
    fn manhattan_distance(a: Position, b: Position) -> u8 {
        ((a.0 - b.0).abs() + (a.1 - b.1).abs()) as u8
    }

    let mut open_set = BinaryHeap::new();
    // let mut came_from: HashMap<Position, Position> = HashMap::new();
    let mut first_step: Option<Position> = None;
    let mut g_costs: HashMap<Position, u8> = HashMap::new();

    let start_node = Node {
        position: start,
        g_cost: 0,
        h_cost: manhattan_distance(start, target),
    };
    open_set.push(start_node);

    while let Some(node) = open_set.pop() {
        if node.position == target {
            // let mut path = vec![node.position];
            // while let Some(prev_pos) = came_from.get(&path.last().unwrap().clone()) {
            //     path.push(*prev_pos);
            //     println!("{:?}", prev_pos);
            // }
            // path.reverse();
            // return Some((node.g_cost, path));
            return Some((node.g_cost, first_step.unwrap()));
        }

        for (dr, dc) in OFFSETS {
            let np @ (nr, nc) = (node.position.0 + dr, node.position.1 + dc);
            if grid[nr as usize][nc as usize] && !unit_positions.contains(&np) {
                let g_cost = node.g_cost + if dr == 0 { 1 } else { 2 };
                let h_cost = manhattan_distance(np, target);

                if let Some(&existing_g_cost) = g_costs.get(&np) {
                    if g_cost >= existing_g_cost {
                        continue;
                    }
                }
                g_costs.insert(np, g_cost);
                let next_node = Node {
                    position: np,
                    g_cost,
                    h_cost,
                };
                open_set.push(next_node);
                // came_from.insert(np, node.position);
            }
        }
        if first_step == None {
            if let Some(pos) = open_set.peek() {
                let (nr, nc) = pos.position;
                let (r, c) = node.position;
                first_step = Some((nr - r, nc - c));
            }
        }
    }
    None
}
