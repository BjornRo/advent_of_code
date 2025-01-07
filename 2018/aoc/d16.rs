use regex::Regex;
use std::collections::{HashMap, HashSet};
use std::fs;

struct Task {
    before: Vec<usize>,
    instruction: Vec<usize>,
    after: Vec<usize>,
}

impl From<Vec<Vec<usize>>> for Task {
    fn from(parts: Vec<Vec<usize>>) -> Self {
        Task {
            before: parts[0].clone(),
            instruction: parts[1].clone(),
            after: parts[2].clone(),
        }
    }
}

type F = fn(&mut Vec<usize>, usize, usize, usize);
fn addr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] + reg[b];
}
fn addi(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] + b;
}
fn mulr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] * reg[b];
}
fn muli(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] * b;
}
fn banr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] & reg[b];
}
fn bani(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] & b;
}
fn borr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] | reg[b];
}
fn bori(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] | b;
}
fn setr(reg: &mut Vec<usize>, a: usize, _: usize, c: usize) {
    reg[c] = reg[a];
}
fn seti(reg: &mut Vec<usize>, a: usize, _: usize, c: usize) {
    reg[c] = a;
}
fn gtir(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = if a > reg[b] { 1 } else { 0 };
}
fn gtri(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = if reg[a] > b { 1 } else { 0 };
}
fn gtrr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = if reg[a] > reg[b] { 1 } else { 0 };
}
fn eqir(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = if a == reg[b] { 1 } else { 0 };
}
fn eqri(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = if reg[a] == b { 1 } else { 0 };
}
fn eqrr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = if reg[a] == reg[b] { 1 } else { 0 };
}

fn part1(tasks: &Vec<Task>) -> (usize, HashMap<usize, HashSet<F>>) {
    let mut op_match: HashMap<usize, HashSet<F>> = HashMap::new();
    let funcs = vec![
        addr, addi, mulr, muli, banr, bani, borr, bori, setr, seti, gtir, gtri, gtrr, eqir, eqri,
        eqrr,
    ];

    let mut total_multiple_ops: usize = 0;
    let mut f_op: Vec<&F> = vec![];
    for task in tasks {
        f_op.clear();
        let [op, a, b, c] = task.instruction[..] else {
            panic!()
        };
        for f in &funcs {
            let mut register = task.before.clone();
            f(&mut register, a, b, c);
            if register == task.after {
                f_op.push(f);
            }
        }
        if f_op.len() >= 3 {
            total_multiple_ops += 1;
        }
        for f in &f_op {
            op_match.entry(op).or_insert_with(HashSet::new).insert(**f);
        }
    }
    (total_multiple_ops, op_match)
}

fn part2(op_matches: &HashMap<usize, HashSet<F>>, test_data: &Vec<Vec<usize>>) -> usize {
    let mut op_matches = op_matches.clone();
    loop {
        for i in 0..16 {
            let set = op_matches.get(&i).unwrap();
            if set.len() == 1 {
                let to_remove = *set.iter().next().unwrap();
                for j in 0..16 {
                    if i == j {
                        continue;
                    }
                    let s = op_matches.get_mut(&j).unwrap();
                    s.remove(&to_remove);
                }
            }
        }
        if op_matches.values().all(|k| k.len() == 1) {
            break;
        }
    }
    let op_map: HashMap<usize, F> = op_matches
        .iter()
        .map(|(k, v)| (*k, *v.iter().next().unwrap()))
        .collect();

    let mut registers = vec![0, 0, 0, 0];
    for task in test_data {
        let [op, a, b, c] = task[..] else { panic!() };
        op_map.get(&op).unwrap()(&mut registers, a, b, c);
    }
    registers[0]
}

fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d16.txt")?;
    let (content, test_data) = binding.trim_end().split_once("\n\n\n\n").unwrap();
    let re = Regex::new(r"(\d+)").unwrap();

    let test_data: Vec<Vec<usize>> = test_data
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
                        .map(|cap| cap[1].parse::<usize>().unwrap())
                        .collect::<Vec<usize>>()
                })
                .collect::<Vec<Vec<usize>>>()
                .into()
        })
        .collect::<Vec<Task>>();

    let (p1, op_matches) = part1(&tasks);
    println!("Part 1: {}", p1);
    println!("Part 2: {}", part2(&op_matches, &test_data));
    Ok(())
}
