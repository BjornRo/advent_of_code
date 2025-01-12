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

fn main() -> std::io::Result<()> {
    let data: Vec<Vec<isize>> = fs::read_to_string("in/d25.txt")?
        .trim_end()
        .lines()
        .map(|line| line.split(",").map(|x| x.parse().unwrap()).collect())
        .collect();

    println!("{:?}", data);
    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
