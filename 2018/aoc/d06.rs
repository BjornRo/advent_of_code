#[allow(unused_imports)]
use chrono::{NaiveDateTime, TimeZone, Timelike, Utc};
#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{
    collections::{HashMap, LinkedList},
    fs,
};

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let contents: Vec<(u64, u64)> = fs::read_to_string("in/d06t.txt")?
        .trim_end()
        .split("\n")
        .map(|x| {
            let values: Vec<u64> = x.split(", ").map(|v| v.parse::<u64>().unwrap()).collect();
            (values[1], values[0]) // I do not like x,y
        })
        .collect();

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
