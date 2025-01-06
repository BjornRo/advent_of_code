use std::cmp::Ordering;
use std::collections::{BinaryHeap, HashMap, HashSet};
use std::fs;

type Position = (i8, i8);
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
struct Unit {
    r#type: UnitType,
    hp: i16,
    attack: i16,
    position: Position,
}

impl Unit {
    fn new(r#type: UnitType, position: Position) -> Self {
        Unit {
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

fn battlefield(mut units: Vec<Unit>, grid: &Vec<Vec<bool>>) -> (usize, bool) {
    let mut rounds = 0;
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
                    units[i].position = next_steps[0];
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
                let all_elves_alive = units
                    .iter()
                    .filter(|u| u.r#type == UnitType::ELF)
                    .all(|u| u.alive());

                let result = units.iter().fold(0, |acc, u| {
                    if u.r#type == unit.r#type && u.alive() {
                        acc + u.hp
                    } else {
                        acc
                    }
                }) as usize
                    * rounds;

                return (result, all_elves_alive);
            }
        }
        rounds += 1;
    }
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
fn main() -> std::io::Result<()> {
    let mut matrix: Vec<Vec<char>> = fs::read_to_string("in/d15.txt")?
        .trim_end()
        .split("\n")
        .map(|row| row.chars().collect())
        .collect();

    let mut units: Vec<Unit> = vec![];

    for i in 0..matrix.len() {
        for j in 0..matrix[0].len() {
            if let Some(r#type) = match matrix[i][j] {
                'G' => Some(UnitType::GOBLIN),
                'E' => Some(UnitType::ELF),
                _ => None,
            } {
                matrix[i][j] = '.';
                units.push(Unit::new(r#type, (i as i8, j as i8)));
            }
        }
    }

    let matrix_bool: Vec<Vec<bool>> = matrix
        .iter()
        .map(|row| row.into_iter().map(|&c| c == '.').collect())
        .collect();

    let p1_result = battlefield(units.clone(), &matrix_bool).0;
    let mut p2_result = 0;

    for i in 4..50 {
        for u in &mut units {
            if u.r#type == UnitType::ELF {
                u.attack = i
            }
        }
        let (value, all_elves_alive) = battlefield(units.clone(), &matrix_bool);
        if all_elves_alive {
            p2_result = value;
            break;
        }
    }

    println!("Part 1: {}", p1_result);
    println!("Part 2: {}", p2_result);
    Ok(())
}
