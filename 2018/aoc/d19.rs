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
                        "eqrr" => Box::new(move |reg: &mut Vec<usize>| reg[c] = if reg[a] == reg[b] { 1 } else { 0 }),
                        _ => panic!(),
                    },
                }
            })
            .unwrap()
    }
}

fn part1(ip: usize, ins: &Vec<Instruction>) -> usize {
    let mut registers = vec![0 as usize; 6];
    while registers[ip] < ins.len() {
        let instruction = &ins[registers[ip]];
        instruction.apply(&mut registers);
        registers[ip] += 1;
    }
    registers[0]
}

fn part2(ip: usize, ins: &Vec<Instruction>) -> usize {
    let mut registers = vec![0 as usize; 6];
    registers[0] = 1;
    let mut last_ip = registers[ip];
    loop {
        let instruction = &ins[registers[ip]];
        instruction.apply(&mut registers);
        registers[ip] += 1;
        if last_ip > registers[ip] {
            break;
        }
        last_ip = registers[ip];
    }
    let max_value = *registers.iter().max().unwrap();
    (1..max_value + 1).fold(0, |acc, x| if max_value % x == 0 { acc + x } else { acc })
}

fn main() -> std::io::Result<()> {
    let (ip, instructions) = fs::read_to_string("in/d19.txt")?
        .trim_end()
        .split_once("\n")
        .map(|(rip, rins)| {
            let ip = (rip.chars().last().unwrap() as u8 - '0' as u8) as usize;
            let ins = rins.lines().map(|r| r.into()).collect::<Vec<Instruction>>();
            (ip, ins)
        })
        .unwrap();

    println!("Part 1: {}", part1(ip, &instructions));
    println!("Part 2: {}", part2(ip, &instructions));
    Ok(())
}
