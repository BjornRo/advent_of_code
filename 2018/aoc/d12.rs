#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

fn str_to_u8(s: &str) -> u8 {
    let res = s
        .chars()
        .rev()
        .map(|c| if c == '#' { 1 } else { 0 } as u8)
        .enumerate()
        .fold(0, |acc, (i, c)| acc | (c << i));
    // println!("{}", s);
    // println!("{}", format!("{:08b}", res));
    res
}

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d12.txt")?;
    let mut content = binding.trim_end().split("\n\n");

    let init_state: Vec<u8> = content
        .next()
        .unwrap()
        .trim_end()
        .split(" ")
        .nth(2)
        .unwrap()
        .chars()
        .map(|c| if c == '#' { 1 } else { 0 })
        .collect();

    let map: HashMap<u8, u8> = content
        .next()
        .unwrap()
        .split("\n")
        .map(|r| {
            let parts: Vec<&str> = r.trim_end().split(" => ").collect();
            (str_to_u8(parts[0]), if parts[1] == "#" { 1 } else { 0 })
        })
        .collect();

    // part1(init_state.clone(), map, 20);
    part2(init_state.clone(), map, 50000000000);

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}

fn part2(mut state: Vec<u8>, map: HashMap<u8, u8>, iterations: u64) {
    let mut next_state: Vec<u8> = vec![];

    let mut last_value: isize = 0;
    let mut last_delta: isize = 0;

    let mut offset: isize = 0;
    for _i in 0..iterations {
        next_state.clear();

        let mut one = false;
        let mut plot: u8 = 0;
        for j in 0..state.len() {
            plot |= state[j];
            let result = *map.get(&plot).unwrap_or(&0);
            if !one {
                if result == 1 {
                    offset += j as isize - 2;
                    one = true;
                    next_state.push(result);
                }
            } else {
                next_state.push(result);
            }
            // println!("{}, {}", format!("{:08b}", plot), result);

            plot <<= 1;
            plot &= 31; // Keep only 5 digits
        }
        // Push out the last bits
        for _ in 0..3 {
            next_state.push(*map.get(&plot).unwrap_or(&0));
            plot <<= 1;
            plot &= 31;
        }
        state = next_state[0..next_state.iter().rposition(|&x| x == 1).unwrap() + 1].to_vec();
        let result: isize = state
            .iter()
            .enumerate()
            .map(|(i, &e)| if e == 1 { i as isize + offset } else { 0 })
            .sum();
        let delta = result - last_value;
        println!(
            "{} {:?} {} {}",
            _i,
            result - last_value,
            result,
            delta == last_delta
        );

        std::thread::sleep(std::time::Duration::from_millis(150));
        last_value = result;
        last_delta = delta;
    }
    let result: isize = state
        .iter()
        .enumerate()
        .map(|(i, &e)| if e == 1 { i as isize + offset } else { 0 })
        .sum();
    println!("{}", result);
}

fn part1(mut state: Vec<u8>, map: HashMap<u8, u8>, iterations: u64) {
    let mut next_state: Vec<u8> = vec![];
    // let mut total: usize = 0;
    let mut offset: isize = 0;
    for _i in 0..iterations {
        next_state.clear();

        let mut one = false;
        let mut plot: u8 = 0;
        for j in 0..state.len() {
            plot |= state[j];
            let result = *map.get(&plot).unwrap_or(&0);
            if !one {
                if result == 1 {
                    offset += j as isize - 2;
                    one = true;
                    next_state.push(result);
                }
            } else {
                next_state.push(result);
            }
            // println!("{}, {}", format!("{:08b}", plot), result);

            plot <<= 1;
            plot &= 31; // Keep only 5 digits
        }
        // Push out the last bits
        for _ in 0..3 {
            next_state.push(*map.get(&plot).unwrap_or(&0));
            plot <<= 1;
            plot &= 31;
        }
        state = next_state[0..next_state.iter().rposition(|&x| x == 1).unwrap() + 1].to_vec();
        // let result: isize = state
        //     .iter()
        //     .enumerate()
        //     .map(|(i, &e)| if e == 1 { i as isize + offset } else { 0 })
        //     .sum();
        // // println()
        // println!("{} {:?}", _i, result);
    }
    let result: isize = state
        .iter()
        .enumerate()
        .map(|(i, &e)| if e == 1 { i as isize + offset } else { 0 })
        .sum();
    println!("{}", result);
}
