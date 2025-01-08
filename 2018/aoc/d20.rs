#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
#![allow(unused_must_use)]
use regex::Regex;
use std::{collections::HashMap, collections::VecDeque, fs};

// 4646 too high
fn door_frames(string: &Vec<char>, mut index: usize) -> (usize, usize) {
    let mut steps: usize = 0;
    let mut msteps: Vec<char> = vec![];
    loop {
        match string[index] {
            '(' => {
                let mut sub_steps = 0;
                loop {
                    let (rec_steps, new_index) = door_frames(string, index + 1);
                    if rec_steps > sub_steps {
                        sub_steps = rec_steps;
                    }
                    index = new_index;
                    if string[new_index] == ')' {
                        steps += sub_steps;
                        break;
                    };
                }
            }
            '|' | ')' | '$' => {
                break;
            }
            _ => {
                msteps.push(string[index]);
                steps += 1
            }
        }
        index += 1;
    }
    println!("{:?} {}", msteps, msteps.len());
    return (steps, index);
}

fn main() -> std::io::Result<()> {
    let string: Vec<char> = fs::read_to_string("in/d20t.txt")?
        .trim_end()
        .chars()
        .collect();

    println!("{:?}", door_frames(&string, 1));
    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
