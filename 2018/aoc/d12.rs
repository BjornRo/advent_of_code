#[allow(unused_imports)]
use regex::Regex;
#[allow(unused_imports)]
use std::{collections::HashMap, collections::VecDeque, fs};

#[allow(unused_mut)]
#[allow(unused_variables)]
fn main() -> std::io::Result<()> {
    let re = Regex::new(r"([.#]{2,})").unwrap();
    let mut content: Vec<String> = re
        .captures_iter(&fs::read_to_string("in/d12t.txt")?)
        .map(|c| c.get(0).unwrap().as_str().to_string())
        .collect();

    let init_state = content.remove(0);

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
