use std::{collections::HashMap, fs};

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d01.txt")?;
    let result: Vec<i32> = contents
        .trim_end()
        .split("\n")
        .map(|s| s.parse::<i32>().unwrap())
        .collect();

    let mut values: HashMap<i32, ()> = HashMap::new();
    let mut sum: i32 = 0;
    'outer: loop {
        for i in &result {
            sum += i;
            if values.contains_key(&sum) {
                break 'outer;
            }
            values.insert(sum, ());
        }
    }

    println!(
        "Part 1: {}",
        result.into_iter().fold(0, |acc, val| acc + val)
    );
    println!("Part 2: {}", sum);
    Ok(())
}
