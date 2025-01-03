use regex::Regex;
use std::{collections::HashMap, fs};

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d04.txt")?;

    let re = Regex::new(r"#(\d+)[\s@]+(\d+),(\d+)[\s:]+(\d+)x(\d+)").unwrap();

    let mut grid: HashMap<(u16, u16), Vec<u16>> = HashMap::new();
    let mut overlaps: HashMap<u16, bool> = HashMap::new();

    for [id, col, row, width, height] in re
        .captures_iter(&contents)
        .map(|c| c.extract().1.map(|x| x.parse::<u16>().unwrap()))
    {
        overlaps.insert(id, false);
        for i in row..row + height {
            for j in col..col + width {
                let value = grid.entry((i, j)).or_insert_with(Vec::new);
                value.push(id);
                if value.len() >= 2 {
                    for k in value {
                        overlaps.insert(*k, true);
                    }
                }
            }
        }
    }

    let p1_res = grid.values().into_iter().filter(|v| v.len() >= 2).count();
    let p2_res = overlaps
        .iter()
        .filter(|(_, v)| !*v)
        .map(|(k, _)| k)
        .last()
        .unwrap();

    println!("Part 1: {}", p1_res);
    println!("Part 2: {}", p2_res);
    Ok(())
}
