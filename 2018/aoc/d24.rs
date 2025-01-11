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

#[derive(Debug)]
enum DamageType {
    Bludgeoning,
    Fire,
    Cold,
    Slashing,
    Radiation,
}

#[derive(Debug)]
struct Unit {
    units: isize,
    hp: isize,
    damage: isize,
    damage_type: DamageType,
    weak: Vec<DamageType>,
    immune: Vec<DamageType>,
    initative: isize,
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

fn parse_line(regex_data: [&str; 6]) -> Unit {
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
        units,
        hp,
        damage,
        damage_type,
        weak,
        immune,
        initative,
    }
}

fn parse_block(raw_block: &str) -> Vec<Unit> {
    let re_par =
        Regex::new(r"^(\d+)[a-z\s]+(\d+)[\w\s]+\(([a-z,;\s]+)\)[a-z\s]+(\d+)\s(\w+)[a-z\s]+(\d+)")
            .unwrap();
    let re = Regex::new(r"^(\d+)[a-z\s]+(\d+)[\w\s]+?[a-z\s]+(\d+) (\w+)[a-z\s]+(\d+)").unwrap();
    raw_block
        .trim_end()
        .lines()
        .skip(1)
        .map(|line| {
            parse_line(if line.contains("(") {
                re_par.captures(line).map(|c| c.extract().1).unwrap()
            } else {
                let [units, hp, damage, damage_type, initative] =
                    re.captures(line).map(|c| c.extract().1).unwrap();
                [units, hp, "", damage, damage_type, initative]
            })
        })
        .collect()
}

fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d24.txt")?;
    let (immune, infection) = binding.trim_end().split_once("\n\n").unwrap();

    let immune = parse_block(immune);
    let infection = parse_block(infection);
    // println!("{:?}", content);
    // println!("Part 1: {}", 1);
    // println!("Part 2: {}", 2);
    Ok(())
}
