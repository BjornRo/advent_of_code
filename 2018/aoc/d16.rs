#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

#[derive(Debug)]
#[allow(dead_code)]
struct Task {
    before: Vec<u8>,
    instruction: Vec<u8>,
    after: Vec<u8>,
}

impl From<Vec<Vec<u8>>> for Task {
    fn from(parts: Vec<Vec<u8>>) -> Self {
        Task {
            before: parts[0].clone(),
            instruction: parts[1].clone(),
            after: parts[2].clone(),
        }
    }
}

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d16.txt")?;
    let (content, test_data) = binding.trim_end().split_once("\n\n\n\n").unwrap();

    let re = Regex::new(r"(\d+)").unwrap();

    let test_data: Vec<Vec<u8>> = test_data
        .trim()
        .lines()
        .map(|row| row.split_whitespace().map(|i| i.parse().unwrap()).collect())
        .collect();

    let tasks = content
        .trim()
        .split("\n\n")
        .map(|sub_task| {
            sub_task
                .lines()
                .map(|task| {
                    re.captures_iter(task)
                        .map(|cap| cap[1].parse::<u8>().unwrap())
                        .collect::<Vec<u8>>()
                })
                .collect::<Vec<Vec<u8>>>()
                .into()
        })
        .collect::<Vec<Task>>();

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
