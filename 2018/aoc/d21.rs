use std::collections::HashSet;
use std::fs;

type Func = Box<dyn Fn(&mut Vec<usize>)>;

struct Instruction {
    func: Func,
}
impl Instruction {
    fn apply(&self, regs: &mut Vec<usize>) {
        (self.func)(regs);
    }
}

impl From<&str> for Instruction {
    #[rustfmt::skip]
    fn from(value: &str) -> Self {
        value
            .split_once(" ")
            .map(|(func, args)| {
                let [a, b, c]: [usize; 3] = args
                    .split_whitespace()
                    .map(|s| s.parse().unwrap())
                    .collect::<Vec<usize>>()
                    .try_into()
                    .expect("");
                Instruction {
                    func: match func {
                        "seti" => Box::new(move |reg: &mut Vec<usize>| reg[c] = a),
                        "setr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a]),
                        "addi" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] + b),
                        "addr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] + reg[b]),
                        "muli" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] * b),
                        "mulr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] * reg[b]),
                        "bani" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] & b),
                        "banr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] & reg[b]),
                        "bori" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] | b),
                        "borr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = reg[a] | reg[b]),
                        "gtri" => Box::new(move |reg: &mut Vec<usize>| reg[c] = (reg[a] > b) as usize),
                        "gtir" => Box::new(move |reg: &mut Vec<usize>| reg[c] = (a > reg[b]) as usize),
                        "gtrr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = (reg[a] > reg[b]) as usize),
                        "eqir" => Box::new(move |reg: &mut Vec<usize>| reg[c] = (a == reg[b]) as usize),
                        "eqri" => Box::new(move |reg: &mut Vec<usize>| reg[c] = (reg[a] == b) as usize),
                        "eqrr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = (reg[a] == reg[b]) as usize),
                        _ => panic!(),
                    },
                }
            })
            .unwrap()
    }
}

fn looper(ip: usize, ins: &Vec<Instruction>) -> (usize, usize) {
    let mut first_terminate = 0;
    let mut last_terminate = 0;

    let mut registers = vec![0 as usize; 6];
    let mut map: HashSet<usize> = HashSet::new();
    loop {
        let reg_ip = registers[ip];
        ins[reg_ip].apply(&mut registers);
        if reg_ip == ins.len() - 1 {
            if first_terminate == 0 {
                first_terminate = registers[5];
            }
            if !map.insert(registers[5]) {
                break;
            }
            last_terminate = registers[5];
        }
        registers[ip] += 1;
    }
    (first_terminate, last_terminate)
}

fn main() -> std::io::Result<()> {
    let (ip, instructions) = fs::read_to_string("in/d21.txt")?
        .trim_end()
        .split_once("\n")
        .map(|(rip, rins)| {
            let ip = (rip.chars().last().unwrap() as u8 - '0' as u8) as usize;
            let ins = rins.lines().map(|r| r.into()).collect::<Vec<Instruction>>();
            (ip, ins)
        })
        .unwrap();

    let (p1, p2) = looper(ip, &instructions);
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
