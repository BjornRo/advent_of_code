#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let [players, points] = fs::read_to_string("in/d10.txt")?
        .split_whitespace()
        .filter(|x| x.chars().any(|c| c.is_ascii_digit()))
        .map(|x| x.parse::<usize>().unwrap())
        .collect::<Vec<usize>>()[..]
    else {
        panic!("nope")
    };

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
