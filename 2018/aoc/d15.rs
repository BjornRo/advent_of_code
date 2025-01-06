#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d15.txt")?;

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

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
