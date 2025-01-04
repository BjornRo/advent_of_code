use std::{collections::HashMap, collections::VecDeque, fs};

fn main() -> std::io::Result<()> {
    let [players, max_marble] = fs::read_to_string("in/d09.txt")?
        .split_whitespace()
        .filter(|x| x.chars().any(|c| c.is_ascii_digit()))
        .map(|x| x.parse::<usize>().unwrap())
        .collect::<Vec<usize>>()[..]
    else {
        panic!("nope")
    };

    let (p1, p2) = gambling(players, max_marble);
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}

fn gambling(players: usize, max_marble: usize) -> (usize, usize) {
    let mut queue: VecDeque<usize> = vec![0].into();
    let mut scores: HashMap<usize, usize> = HashMap::new();

    let mut p1_result: usize = 0;

    let mut removed_marbles: usize = 0;
    for i in 1..max_marble * 100 {
        if i % 23 == 0 {
            queue.rotate_right(7);
            *scores.entry(i % players).or_insert(0) += queue.pop_back().unwrap() + i;
            removed_marbles += 2; // We pop and also do not add, offset by 2
            queue.rotate_left(1);
        } else {
            queue.rotate_left((i + 1 - removed_marbles) % queue.len());
            queue.push_back(i);
        }
        if i == max_marble {
            p1_result = *scores.values().max().unwrap();
        }
    }
    (p1_result, *scores.values().max().unwrap())
}
