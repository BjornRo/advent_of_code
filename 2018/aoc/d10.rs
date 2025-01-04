use regex::Regex;
use std::{collections::HashMap, fs};

#[derive(Debug, Clone)]
struct Point {
    pos: (isize, isize),
    vel: (isize, isize),
}

impl Point {
    fn step(&self, i: isize) -> (isize, isize) {
        let (vr, vc) = self.vel;
        let (r, c) = self.pos;
        (r + vr * i, c + vc * i)
    }
}

impl From<[(isize, isize); 2]> for Point {
    fn from(i: [(isize, isize); 2]) -> Self {
        Point {
            pos: i[0],
            vel: i[1],
        }
    }
}

fn printer(map: Vec<(isize, isize)>) {
    let min_row = map.iter().map(|(r, _)| r).min().unwrap() - 1;
    let max_row = map.iter().map(|(r, _)| r).max().unwrap() + 1;
    let min_col = map.iter().map(|(_, c)| c).min().unwrap() - 1;
    let max_col = map.iter().map(|(_, c)| c).max().unwrap() + 1;
    let rows = (max_row - min_row + 1) as usize;
    let cols = (max_col - min_col + 1) as usize;
    let mut matrix = vec![vec![" ".to_string(); cols]; rows];
    for (r, c) in map {
        matrix[(r - min_row) as usize][(c - min_col) as usize] = "#".to_string();
    }
    for row in matrix {
        println!("{}", row.concat());
    }
}

fn dfs(
    points: &Vec<Point>,
    initial_points: usize,
    threshold: usize,
) -> (isize, Vec<(isize, isize)>) {
    let mut visited: HashMap<(isize, isize), ()> = HashMap::new();

    let mut i: isize = 0;
    loop {
        visited.clear();

        let map: HashMap<(isize, isize), ()> = points.iter().map(|p| (p.step(i), ())).collect();
        let mut stack: Vec<(isize, isize)> = map.keys().take(initial_points).cloned().collect();

        while stack.len() != 0 {
            let p @ (row, col) = stack.pop().unwrap();

            if visited.contains_key(&p) {
                continue;
            }
            visited.insert(p, ());

            if visited.len() >= threshold {
                return (i, map.keys().cloned().collect::<Vec<(isize, isize)>>());
            }

            for (nr, nc) in [(0, 1), (1, 0), (0, -1), (-1, 0)] {
                let np = (row + nr, col + nc);
                if let Some(_) = map.get(&np) {
                    stack.push(np);
                }
            }
        }
        i += 1;
    }
}

fn main() -> std::io::Result<()> {
    let content = fs::read_to_string("in/d10.txt")?;
    let re = Regex::new(r"<(.*)>.*<(.*)>").unwrap();

    let points: Vec<Point> = re
        .captures_iter(&content)
        .map(|c| {
            c.extract().1.map(|s| {
                let value: Vec<isize> = s
                    .split(',')
                    .map(|v| v.trim().parse::<isize>().unwrap())
                    .collect();
                (value[1], value[0])
            })
        })
        .map(|arr| arr.into())
        .collect();

    let (index, map) = dfs(&points, 8, 28);

    println!("Part 1:");
    printer(map);

    println!("Part 2: {}", index);
    Ok(())
}
