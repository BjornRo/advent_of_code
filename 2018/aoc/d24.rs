#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
#![allow(unused_must_use)]
use regex::Regex;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;

#[allow(dead_code)]
fn print<T: std::fmt::Debug>(x: T) {
    println!("{:?}", x);
}

type ID = usize;
type TargetType = (ID, UnitType);

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
enum UnitType {
    Immune,
    Infection,
}
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum DamageType {
    Bludgeoning,
    Fire,
    Cold,
    Slashing,
    Radiation,
}

#[derive(Debug, Clone)]
struct Unit {
    id: ID,
    r#type: UnitType,
    units: isize,
    hp: isize,
    damage: isize,
    damage_type: DamageType,
    weak: Vec<DamageType>,
    immune: Vec<DamageType>,
    initative: isize,
    target: Option<TargetType>,
}
impl Unit {
    fn effective_power(&self) -> isize {
        self.units * self.damage
    }
}

fn str_to_damagetype(raw_str: &str) -> DamageType {
    use DamageType::*;
    match raw_str {
        "bludgeoning" => Bludgeoning,
        "fire" => Fire,
        "cold" => Cold,
        "slashing" => Slashing,
        "radiation" => Radiation,
        x => panic!("{}", x),
    }
}

fn str_to_damagetype_vec(raw_str: &str) -> Vec<DamageType> {
    use DamageType::*;
    raw_str
        .split_whitespace()
        .skip(2)
        .map(|s| str_to_damagetype(s.trim_end_matches(",")))
        .collect()
}

fn parse_line(regex_data: [&str; 6], id: usize, unit_type: UnitType) -> Unit {
    let [units, hp, weak_immune, damage, damage_type, initative] = regex_data;
    let units: isize = units.parse().unwrap();
    let hp: isize = hp.parse().unwrap();
    let damage: isize = damage.parse().unwrap();
    let damage_type = str_to_damagetype(damage_type);
    let initative: isize = initative.parse().unwrap();
    let (weak, immune): (Vec<DamageType>, Vec<DamageType>) = if weak_immune.is_empty() {
        (vec![], vec![])
    } else {
        if weak_immune.contains(";") {
            let (mut left, mut right) = weak_immune.split_once("; ").unwrap();
            if left.starts_with("immune") {
                let tmp = left;
                left = right;
                right = tmp;
            }
            (str_to_damagetype_vec(left), str_to_damagetype_vec(right))
        } else {
            if weak_immune.starts_with("weak") {
                (str_to_damagetype_vec(weak_immune), vec![])
            } else {
                (vec![], str_to_damagetype_vec(weak_immune))
            }
        }
    };
    Unit {
        id,
        r#type: unit_type,
        units,
        hp,
        damage,
        damage_type,
        weak,
        immune,
        initative,
        target: None,
    }
}

fn parse_block(raw_block: &str, unit_type: UnitType) -> Vec<Unit> {
    let re_par =
        Regex::new(r"^(\d+)[a-z\s]+(\d+)[\w\s]+\(([a-z,;\s]+)\)[a-z\s]+(\d+)\s(\w+)[a-z\s]+(\d+)")
            .unwrap();
    let re = Regex::new(r"^(\d+)[a-z\s]+(\d+)[\w\s]+?[a-z\s]+(\d+) (\w+)[a-z\s]+(\d+)").unwrap();
    raw_block
        .trim_end()
        .lines()
        .skip(1)
        .enumerate()
        .map(|(id, line)| {
            parse_line(
                if line.contains("(") {
                    re_par.captures(line).map(|c| c.extract().1).unwrap()
                } else {
                    let [units, hp, damage, damage_type, initative] =
                        re.captures(line).map(|c| c.extract().1).unwrap();
                    [units, hp, "", damage, damage_type, initative]
                },
                id + 1,
                unit_type,
            )
        })
        .collect()
}

fn part1(mut groups: Vec<Unit>) -> isize {
    use UnitType::*;
    let mut selected_targets: HashSet<TargetType> = HashSet::new();
    loop {
        selected_targets.clear();
        groups.sort_unstable_by_key(|x| (-x.effective_power(), -x.initative));
        for i in 0..groups.len() {
            let mut targets: Vec<_> = groups
                .iter()
                .filter(|y| {
                    groups[i].r#type != y.r#type
                        && !selected_targets.contains(&(y.id, y.r#type))
                        && !y.immune.contains(&groups[i].damage_type)
                })
                .map(|y| {
                    let mut power = groups[i].effective_power();
                    if y.weak.contains(&groups[i].damage_type) {
                        power *= 2;
                    }
                    (y.id, power, y.effective_power(), y.initative, y.r#type)
                })
                .collect();
            if targets.len() == 0 {
                groups[i].target = None;
                continue;
            }
            targets.sort_unstable_by_key(|(_, myp, p, i, _)| (-myp, -p, -i));
            print(&groups[i]);
            print(&targets);
            print("");
            let t = targets[0];
            let (id, _, _, _, ut) = t;
            selected_targets.insert((id, ut));
            groups[i].target = Some((id, ut));
        }

        groups.sort_unstable_by_key(|x| -x.initative);
        for i in 0..groups.len() {
            if let Some((id, unit_type)) = groups[i].target {
                let mut damage = groups[i].effective_power();
                let dmg_type = groups[i].damage_type;
                print(&groups[i]);
                let mut target = groups
                    .iter_mut()
                    .find_map(|x| {
                        if x.id == id && x.r#type == unit_type {
                            Some(x)
                        } else {
                            None
                        }
                    })
                    .unwrap();
                print(&target);
                if target.weak.contains(&dmg_type) {
                    damage *= 2;
                }
                let lost_units = damage / target.hp;
                print(damage);
                print(lost_units);
                target.units -= lost_units;
            }
            groups[i].target = None;
        }
        print("new round");
        groups.retain(|x| x.units > 0);
        if !groups.iter().any(|x| x.r#type == Immune) {
            print("Infect wins");
            print(&groups);
            return groups.iter().map(|x| x.units).sum();
        } else if !groups.iter().any(|x| x.r#type == Infection) {
            print("Immune wins");
            return groups.iter().map(|x| x.units).sum();
        }
    }
}

fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d24.txt")?;
    let (immune, infection) = binding.trim_end().split_once("\n\n").unwrap();

    let immune = parse_block(immune, UnitType::Immune);
    let infection = parse_block(infection, UnitType::Infection);

    // println!("{:?}", content);
    println!("Part 1: {}", part1([immune.clone(), infection].concat()));
    // println!("Part 2: {}", 2);
    Ok(())
}
