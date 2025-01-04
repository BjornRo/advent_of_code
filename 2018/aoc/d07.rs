use regex::Regex;
use std::{collections::HashMap, fs};

fn part1(
    map: &HashMap<char, Vec<char>>,
    requires: &HashMap<char, Vec<char>>,
    num_chars: usize,
) -> String {
    let mut stack: Vec<char> = map
        .keys()
        .filter(|c| requires.get(c) == None)
        .cloned()
        .collect();
    stack.sort_unstable();

    let mut visited: Vec<char> = Vec::new();
    while visited.len() != num_chars {
        let step = stack.remove(0);

        if visited.contains(&step) {
            continue;
        }

        let require = requires.get(&step);
        if require == None || require.unwrap().iter().all(|c| visited.contains(c)) {
            visited.push(step);
            if let Some(value) = map.get(&step) {
                stack.append(&mut value.clone());
                stack.sort_unstable();
            }
        } else {
            stack.push(step);
        }
    }
    visited.into_iter().collect::<String>()
}

#[derive(PartialEq, Clone)]
struct Task {
    counter: u8,
    character: char,
}

impl Task {
    fn new(delta: u8, character: char) -> Self {
        let count = character as u8 - 'A' as u8 + 1 + delta;
        Task {
            counter: count,
            character,
        }
    }
    fn tick(&mut self) -> Option<char> {
        self.counter -= 1;
        if self.counter == 0 {
            Some(self.character)
        } else {
            None
        }
    }
}

fn part2(
    map: &HashMap<char, Vec<char>>,
    requires: &HashMap<char, Vec<char>>,
    num_chars: usize,
    num_workers: usize,
    delta_time: u8,
) -> u32 {
    let mut stack: Vec<char> = map
        .keys()
        .filter(|c| requires.get(c) == None)
        .cloned()
        .collect();
    stack.sort_unstable();

    let mut seconds: u32 = 0;
    let mut workers: Vec<Task> = Vec::new();
    let mut finished: Vec<char> = Vec::new();
    while finished.len() != num_chars {
        loop {
            if workers.len() == num_workers || stack.is_empty() {
                break;
            }
            workers.push(Task::new(delta_time, stack.remove(0)));
        }
        workers = workers
            .iter_mut()
            .map(|i| {
                if let Some(step) = i.tick() {
                    finished.push(step);
                    if let Some(successors) = map.get(&step) {
                        for succ in successors {
                            if finished.contains(succ) {
                                continue;
                            }
                            let r = requires.get(&succ);
                            if r == None || r.unwrap().iter().all(|c| finished.contains(c)) {
                                stack.push(*succ);
                            };
                        }
                        stack.sort_unstable();
                    }
                    None
                } else {
                    Some(i)
                }
            })
            .filter(|i| *i != None)
            .map(|i| i.unwrap().clone())
            .collect::<Vec<Task>>();
        seconds += 1;
    }
    seconds
}

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d07.txt")?;
    let re = Regex::new(r".+([A-Z]).+([A-Z]).+").unwrap();

    let mut all_chars: HashMap<char, ()> = HashMap::new();
    let mut map: HashMap<char, Vec<char>> = HashMap::new();
    let mut requires: HashMap<char, Vec<char>> = HashMap::new();

    for [a, b] in re
        .captures_iter(&contents)
        .map(|c| c.extract().1.map(|c| c.chars().next().unwrap()))
    {
        let value = map.entry(a).or_insert_with(Vec::new);
        value.push(b);
        value.sort_unstable();
        let value = requires.entry(b).or_insert_with(Vec::new);
        value.push(a);
        value.sort_unstable();
        all_chars.insert(a, ());
        all_chars.insert(b, ());
    }

    println!("Part 1: {}", part1(&map, &requires, all_chars.len()));
    println!("Part 2: {}", part2(&map, &requires, all_chars.len(), 5, 60));
    Ok(())
}
