use std::fs;

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d03.txt")?;
    let data: Vec<&str> = contents.trim_end().split("\n").collect();

    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
