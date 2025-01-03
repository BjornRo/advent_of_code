use std::{collections::HashMap, fs, vec};

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d02.txt")?;
    let data: Vec<&str> = contents.trim_end().split("\n").collect();

    let mut twice = 0;
    let mut thrice = 0;

    let mut counter: HashMap<u8, u8> = HashMap::new();
    for i in &data {
        for c in i.chars() {
            *counter.entry(c as u8).or_insert(0) += 1;
        }
        let mut tw = false;
        let mut th = false;
        for (_, v) in counter.drain() {
            if v == 2 {
                tw = true;
            } else if v == 3 {
                th = true;
            }
        }
        twice += if tw { 1 } else { 0 };
        thrice += if th { 1 } else { 0 };
    }

    let mut common: Vec<char> = vec![];
    'outer: for (i, &elem0) in data.iter().enumerate() {
        for &elem1 in data.iter().skip(i + 1) {
            common = elem0
                .chars()
                .zip(elem1.chars())
                .filter(|(a, b)| a == b)
                .map(|(a, _)| a)
                .collect();
            if (common.len() as i8 - elem1.len() as i8).abs() <= 1 {
                break 'outer;
            }
        }
    }

    println!("Part 1: {}", twice * thrice);
    println!("Part 2: {}", common.into_iter().collect::<String>());
    Ok(())
}
