#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, fs};

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d08.txt")?
        .trim_end()
        .split(" ")
        .map(|x| x.parse::<usize>().unwrap())
        .collect::<Vec<usize>>();

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
