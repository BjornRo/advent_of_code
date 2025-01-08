#![allow(dead_code)]
#![allow(unused_imports)]
#![allow(unused_mut)]
#![allow(unused_variables)]
#![allow(unused_assignments)]
#![allow(unused_must_use)]
use regex::Regex;
use std::{collections::HashMap, collections::VecDeque, fs};

fn addr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] + reg[b];
}
fn addi(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a] + b;
}
fn setr(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = reg[a];
}
fn seti(reg: &mut Vec<usize>, a: usize, b: usize, c: usize) {
    reg[c] = a;
}

#[derive(Debug)]
struct Instruction {
    func: fn(&mut Vec<usize>, usize, usize, usize),
    args: (u8, u8, u8),
}
impl Instruction {
    fn apply(&self, registers: &mut Vec<usize>) {
        (self.func)(
            registers,
            self.args.0 as usize,
            self.args.1 as usize,
            self.args.2 as usize,
        )
    }
}

impl From<&str> for Instruction {
    fn from(value: &str) -> Self {
        value
            .split_once(" ")
            .map(|(func, args)| {
                let [a, b, c]: [u8; 3] = args
                    .split_whitespace()
                    .map(|s| s.parse::<u8>().unwrap())
                    .collect::<Vec<u8>>()
                    .try_into()
                    .expect("");
                Instruction {
                    func: match func {
                        "seti" => seti,
                        "setr" => seti,
                        "addi" => addi,
                        "addr" => addr,
                        _ => panic!(),
                    },
                    args: (a, b, c),
                }
            })
            .unwrap()
    }
}

fn part1(mut ip: usize, ins: &Vec<Instruction>) {
    let mut registers = vec![0 as usize; 6];
    while ip < registers.len() {
        let instruction = &ins[registers[ip]];
        instruction.apply(&mut registers);
        ip = registers[ip];
        println!("{:?}", registers);
    }
    println!("{:?}", registers);
}

fn main() -> std::io::Result<()> {
    let (ip, instructions) = fs::read_to_string("in/d19t.txt")?
        .trim_end()
        .split_once("\n")
        .map(|(rip, rins)| {
            let ip = rip.chars().last().unwrap() as u8 - '0' as u8;
            let ins = rins.lines().map(|r| r.into()).collect::<Vec<Instruction>>();
            (ip, ins)
        })
        .unwrap();

    part1(ip as usize, &instructions);

    println!("{:?}", instructions);
    println!("Part 1: {}", 1);
    println!("Part 2: {}", 2);
    Ok(())
}
