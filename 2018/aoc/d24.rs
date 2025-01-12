use regex::Regex;
use std::collections::HashSet;
use std::fs;

use UnitType::*;
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

fn solver(mut groups: Vec<Unit>) -> [isize; 2] {
    let mut selected_targets: HashSet<TargetType> = HashSet::new();
    let mut result: [isize; 2] = [-1, -1];
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
            let (id, _, _, _, ut) = targets[0];
            selected_targets.insert((id, ut));
            groups[i].target = Some((id, ut));
        }

        groups.sort_unstable_by_key(|x| -x.initative);
        for i in 0..groups.len() {
            if let Some((id, unit_type)) = groups[i].target {
                let mut damage = groups[i].effective_power();
                let dmg_type = groups[i].damage_type;
                let target = groups
                    .iter_mut()
                    .find_map(|x| {
                        if x.id == id && x.r#type == unit_type {
                            Some(x)
                        } else {
                            None
                        }
                    })
                    .unwrap();
                if target.weak.contains(&dmg_type) {
                    damage *= 2;
                }
                target.units -= damage / target.hp;
            }
        }
        groups.retain(|x| x.units > 0);
        let new_result = groups.iter().fold([0, 0], |[imm, inf], x| match x.r#type {
            Immune => [imm + x.units, inf],
            Infection => [imm, inf + x.units],
        });
        if new_result.contains(&0) {
            return new_result;
        } else if new_result == result {
            // Deadlock
            return [0, 0];
        }
        result = new_result;
    }
}

fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d24.txt")?;
    let (immune, infection) = binding.trim_end().split_once("\n\n").unwrap();

    let immune = parse_block(immune, Immune);
    let infection = parse_block(infection, Infection);

    let mut p2 = 0;
    for i in 1..1 << 32 {
        let mut immune = immune.clone();
        for m in immune.iter_mut() {
            m.damage += i;
        }
        p2 = solver([immune, infection.clone()].concat())[0];
        if p2 > 0 {
            break;
        }
    }

    println!(
        "Part 1: {}",
        solver([immune.clone(), infection.clone()].concat())
            .iter()
            .find(|&&x| x != 0)
            .unwrap()
    );
    println!("Part 2: {}", p2);
    Ok(())
}
