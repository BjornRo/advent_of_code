#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::cmp::Ordering;
#[allow(unused_imports)]
use std::collections::{BinaryHeap, HashMap, HashSet};
#[allow(unused_imports)]
use std::{fs, io};

type Position = (i8, i8);
// Order is important, most important to least (rules of the puzzle)
const OFFSETS: [Position; 4] = [(-1, 0), (0, -1), (0, 1), (1, 0)];

#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
struct Node {
    position: Position,
    cost: u8,
}
impl Node {
    fn cost(&self) -> u8 {
        self.cost
    }
}
impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        other.cost().cmp(&self.cost())
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
    let mut rounds = 0;
    _ = rounds;
    loop {
        units.sort_unstable_by_key(|u| (u.position.0, u.position.1));
        for i in 0..units.len() {
            let unit = units[i].clone();
            if !unit.alive() {
                continue;
            }

            let unit_positions: HashMap<Position, UnitType> = units
                .iter()
                .filter(|u| u.alive())
                .map(|u| (u.position, u.r#type.clone()))
                .collect();

            let enemy_adjacent = OFFSETS.iter().any(|(dr, dc)| {
                &unit.r#type
                    != unit_positions
                        .get(&(unit.position.0 + dr, unit.position.1 + dc))
                        .unwrap_or(&unit.r#type)
            });
            if !enemy_adjacent {
                let targets: Vec<&Unit> = units
                    .iter()
                    .filter(|o| o.r#type != unit.r#type && o.alive())
                    .collect();
                let end_positions: Vec<Position> = targets
                    .iter()
                    .flat_map(|o| {
                        OFFSETS.iter().filter_map(|(dr, dc)| {
                            let np @ (row, col) = (o.position.0 - dr, o.position.1 - dc);
                            if unit.position == np {
                                return Some(np);
                            }
                            if !grid[row as usize][col as usize] || unit_positions.contains_key(&np)
                            {
                                None
                            } else {
                                Some(np)
                            }
                        })
                    })
                    .collect();

                let mut paths: Vec<_> = end_positions
                    .iter()
                    .filter_map(|&end_pos| dijkstra(end_pos, unit.position, grid, &unit_positions))
                    .collect();

                if paths.len() >= 1 {
                    paths.sort_unstable_by_key(|&(v, _)| v);
                    let (cost, _) = &paths[0];
                    let mut next_steps: Vec<Position> = paths
                        .iter()
                        .filter(|(pcost, _)| pcost == cost)
                        .flat_map(|(_, map)| {
                            OFFSETS.iter().filter_map(move |(dr, dc)| {
                                let np = (unit.position.0 + dr, unit.position.1 + dc);
                                if Some(cost) == map.get(&np) {
                                    Some(np)
                                } else {
                                    None
                                }
                            })
                        })
                        .collect();
                    next_steps.sort_unstable();
                    // if unit.r#type == UnitType::GOBLIN && units[i].id == 4 {
                    //     println!("id {:?}", units[i].id);
                    //     println!("pos {:?}", units[i].position);
                    //     println!("ns {:?}", next_steps);
                    //     println!("ends {:?}", end_positions);
                    //     println!("{:?}", paths[0]);
                    //     println!("{:?}", unit_positions);
                    // }
                    units[i].position = next_steps[0];
                    // println!("{} {:?}", units[i].id, next_steps);
                    // for i in &units {
                    //     println!("{:?}", i);
                    // }
                }
            }
            let adjacent: Vec<Position> = OFFSETS
                .iter()
                .map(|&(dr, dc)| (units[i].position.0 + dr, units[i].position.1 + dc))
                .collect();
            let mut targets: Vec<&mut Unit> = units
                .iter_mut()
                .filter(|u| adjacent.contains(&u.position) && u.r#type != unit.r#type && u.alive())
                .collect();

            if targets.len() >= 1 {
                targets.sort_unstable_by_key(|u| (u.hp, u.position));
                targets[0].hp -= unit.attack;
            }

            let targets: Vec<&Unit> = units
                .iter()
                .filter(|o| o.r#type != unit.r#type && o.alive())
                .collect();
            if targets.len() == 0 {
                for i in &units {
                    if i.r#type == UnitType::ELF {
                        println!("{:?}", i.alive());
                    }
                }
                // println!("{:?}", units);
                println!("{:?} wins", unit.r#type);
                // for i in &units {
                //     println!("{:?}", i);
                // }

                let result = units.iter().fold(0, |acc, u| {
                    if u.r#type == unit.r#type && u.alive() {
                        acc + u.hp
                    } else {
                        acc
                    }
                });
                println!(
                    "hp: {}, rounds: {}, outcome: {}",
                    result,
                    rounds,
                    result as usize * rounds as usize
                );

                return;
            }
        }
        rounds += 1;
        // println!("round {}", rounds);
        // for i in &units {
        //     println!("{:?}", i);
        // }
        // wait_input();
    }
    //
}

#[allow(dead_code)]
fn dijkstra(
    start: Position,
    target: Position,
    grid: &Vec<Vec<bool>>,
    unit_positions: &HashMap<Position, UnitType>,
) -> Option<(u8, HashMap<Position, u8>)> {
    let mut costs: HashMap<Position, u8> = HashMap::new();
    let mut visited: HashSet<Position> = HashSet::new();
    let mut heap = BinaryHeap::new();

    costs.insert(start, 0);
    heap.push(Node {
        position: start,
        cost: 0,
    });

    while let Some(node) = heap.pop() {
        if node.position == target {
            // if start == (2, 1) {
            //     println!("c {:?}", costs);
            //     println!("st {:?},{:?}", start, target);
            //     println!("u {:?}", unit_positions);
            // }
            return Some((node.cost - 1, costs));
        }

        if visited.contains(&node.position) {
            continue;
        }
        visited.insert(node.position);
        for (dr, dc) in OFFSETS {
            let np @ (nr, nc) = (node.position.0 + dr, node.position.1 + dc);
            if grid[nr as usize][nc as usize] && (!unit_positions.contains_key(&np) || np == target)
            {
                // if start == (2, 1) {
                //     println!("vx {:?}", np);
                //     println!(
                //         "tt {:?}",
                //         !unit_positions.contains_key(&node.position) || np == target
                //     );
                // }
                let new_cost = node.cost + 1;
                let entry = costs.entry(np).or_insert(u8::MAX);

                if new_cost < *entry {
                    *entry = new_cost;
                    heap.push(Node {
                        position: np,
                        cost: new_cost,
                    });
                }
            }
        }
    }
    None
}

// if unit.r#type == UnitType::ELF {
//     println!("{:?}", targets[*target as usize]);
//     // println!("{:?}", targets);
// }
// // println!("{:?}", units[i]);
// for i in units.clone() {
//     println!("{:?}", i);
// }
// for i in &units {
//     println!("{:?}", i);
// }
// println!("over");
// for i in &units {
//     println!("{:?}", i);
// }

// println!("{:?}", paths[0].1.get(&(1, 2)));
// println!("{:?}", paths[1].1.get(&(1, 2)));
// println!("{:?}", paths[0].1.get(&(2, 1)));
// println!("{:?}", paths[1].1.get(&(2, 1)));
// println!("{:?}", paths[1]);

// units[i].position.0 += paths[0].1 .0;
// units[i].position.1 += paths[0].1 .1;

// println!("{:?}", paths);
// println!("{:?}", units[i]);

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let mut matrix: Vec<Vec<char>> = fs::read_to_string("in/d15.txt")?
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

    for i in 4..50 {
        for u in &mut units {
            if u.r#type == UnitType::ELF {
                u.attack = i
            }
        }
        part1(units.clone(), &matrix_bool);
        wait_input();
    }

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}

#[allow(dead_code)]
fn wait_input() {
    let mut input = String::new();
    io::stdin()
        .read_line(&mut input)
        .expect("Failed to read line");
}
