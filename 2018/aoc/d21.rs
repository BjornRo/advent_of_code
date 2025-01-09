#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
#![allow(unused_must_use)]
use regex::Regex;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;

fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d21t.txt")?;

    let re = Regex::new(r"<(.*)>.*<(.*)>").unwrap();

    let points: Vec<Point> = re
        .captures_iter(&content)
        .map(|c| {
            c.extract().1.map(|s| {
                let value: Vec<isize> = s
                    .split(',')
                    .map(|v| v.trim().parse::<isize>().unwrap())
                    .collect();
                (value[1], value[0])
            })
        })
        .map(|arr| arr.into())
        .collect();

    println!("{:?}", content);
    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
