use num::Complex;
use std::fs;

const LEFT_TURN: Complex<isize> = Complex::new(0, 1);
const RIGHT_TURN: Complex<isize> = Complex::new(0, -1);
const IDENTITY: Complex<isize> = Complex::new(1, 0);
const UP: Complex<isize> = Complex::new(-1, 0);
const DOWN: Complex<isize> = Complex::new(1, 0);
const LEFT: Complex<isize> = Complex::new(0, -1);
const RIGHT: Complex<isize> = Complex::new(0, 1);

#[derive(Debug, Clone)]
struct Cart {
    id: usize,
    pos: Complex<isize>,
    dir: Complex<isize>,
    crashed: bool,
    cross_turn: Complex<isize>,
}

impl Cart {
    fn eq_pos(&self, other: &Self) -> bool {
        self.id != other.id && self.pos == other.pos
    }
    fn print(&self) -> String {
        format!("{},{}", self.pos.im, self.pos.re)
    }
    fn tick(&mut self, grid: &Vec<Vec<char>>) {
        self.pos += self.dir;
        match grid[self.pos.re as usize][self.pos.im as usize] {
            '\\' => {
                self.dir *= if self.dir == RIGHT || self.dir == LEFT {
                    RIGHT_TURN
                } else {
                    LEFT_TURN
                }
            }
            '/' => {
                self.dir *= if self.dir == RIGHT || self.dir == LEFT {
                    LEFT_TURN
                } else {
                    RIGHT_TURN
                }
            }
            '+' => {
                self.dir *= self.cross_turn;
                if self.cross_turn == LEFT_TURN {
                    self.cross_turn = IDENTITY;
                } else if self.cross_turn == IDENTITY {
                    self.cross_turn = RIGHT_TURN;
                } else {
                    self.cross_turn = LEFT_TURN;
                }
            }
            _ => {}
        }
    }
}

fn solver(matrix: &Vec<Vec<char>>, mut carts: Vec<Cart>) -> (String, String) {
    let mut alive_carts = carts.len();
    let mut p1: Option<String> = None;
    loop {
        carts.sort_by_key(|cart| (cart.pos.re, cart.pos.im));
        for i in 0..carts.len() {
            if carts[i].crashed {
                continue;
            }
            carts[i].tick(matrix);
            for j in 0..carts.len() {
                if carts[j].crashed {
                    continue;
                }
                if carts[i].eq_pos(&carts[j]) {
                    if p1 == None {
                        p1 = Some(carts[i].print())
                    }
                    carts[i].crashed = true;
                    carts[j].crashed = true;
                    alive_carts -= 2;
                    break;
                }
            }
        }
        if alive_carts <= 1 {
            for i in &carts {
                if !i.crashed {
                    return (p1.unwrap(), i.print());
                }
            }
        }
    }
}

fn main() -> std::io::Result<()> {
    let mut matrix: Vec<Vec<char>> = fs::read_to_string("in/d13.txt")?
        .trim_end_matches("\n")
        .split("\n")
        .map(|row| row.chars().collect())
        .collect();
    let mut carts: Vec<Cart> = vec![];

    let mut id: usize = 0;
    for i in 0..matrix.len() {
        for j in 0..matrix[0].len() {
            if let Some(dir) = match matrix[i][j] {
                '^' => {
                    matrix[i][j] = '|';
                    Some(UP)
                }
                'v' => {
                    matrix[i][j] = '|';
                    Some(DOWN)
                }
                '>' => {
                    matrix[i][j] = '-';
                    Some(RIGHT)
                }
                '<' => {
                    matrix[i][j] = '-';
                    Some(LEFT)
                }
                _ => None,
            } {
                carts.push(Cart {
                    id,
                    pos: Complex::new(i as isize, j as isize),
                    dir,
                    crashed: false,
                    cross_turn: LEFT_TURN,
                });
                id += 1;
            }
        }
    }

    let (p1, p2) = solver(&matrix, carts.clone());
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
