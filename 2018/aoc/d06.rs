use std::{collections::HashMap, fs};

struct Matrix {
    data: Vec<Option<usize>>,
    rows: usize,
    cols: usize,
}

impl Matrix {
    fn new(rows: usize, cols: usize, initial_value: Option<usize>) -> Self {
        let data = vec![initial_value; rows * cols];
        Matrix { data, rows, cols }
    }

    fn get(&self, i: i32, j: i32) -> Option<Option<usize>> {
        if 0 <= i && i < self.rows as i32 && 0 <= j && j < self.cols as i32 {
            let index = i as usize * self.cols + j as usize;
            Some(self.data[index])
        } else {
            None
        }
    }

    fn set(&mut self, i: usize, j: usize, value: Option<usize>) {
        if i < self.rows && j < self.cols {
            let index = i * self.cols + j;
            self.data[index] = value;
        }
    }
}

fn manhattan(a: (usize, usize), b: (usize, usize)) -> usize {
    a.0.abs_diff(b.0) + a.1.abs_diff(b.1)
}

fn floodfill(matrix: &Matrix, point: (usize, usize), id: usize) -> Option<usize> {
    let mut stack = vec![point];
    let mut visited: HashMap<(usize, usize), ()> = HashMap::new();

    while !stack.is_empty() {
        let p @ (row, col) = stack.pop().unwrap();

        if visited.insert(p, ()) != None {
            continue;
        }
        for (dr, dc) in [(0, 1), (1, 0), (0, -1), (-1, 0)] {
            let (nr, nc) = (row as i32 - dr, col as i32 - dc);
            if let Some(valid_pos) = matrix.get(nr, nc) {
                if let Some(value) = valid_pos {
                    if value == id {
                        stack.push((nr as usize, nc as usize));
                    }
                }
            } else {
                return None; // Not infinity!
            }
        }
    }

    return Some(visited.len());
}

fn main() -> std::io::Result<()> {
    let contents: Vec<(usize, usize)> = fs::read_to_string("in/d06.txt")?
        .trim_end()
        .split("\n")
        .map(|x| {
            let values: Vec<usize> = x.split(", ").map(|v| v.parse::<usize>().unwrap()).collect();
            (values[1], values[0]) // I do not like x,y
        })
        .collect();

    let (min_row, mut max_row, min_col, mut max_col) = contents.iter().fold(
        (usize::MAX, usize::MIN, usize::MAX, usize::MIN),
        |(min_row, max_row, min_col, max_col), &(x, y)| {
            (
                min_row.min(x),
                max_row.max(x),
                min_col.min(y),
                max_col.max(y),
            )
        },
    );
    max_row -= min_row - 1;
    max_col -= min_col - 1;

    let mut matrix = Matrix::new(max_row, max_col, None);
    let points: Vec<(usize, usize)> = contents
        .iter()
        .map(|(row, col)| (row - min_row, col - min_col))
        .collect();

    for i in 0..max_row {
        for j in 0..max_col {
            let mut result: Vec<(usize, usize)> = points
                .iter()
                .enumerate()
                .map(|(k, p)| (k, manhattan((i, j), *p)))
                .collect();
            result.sort_by(|a, b| a.1.cmp(&b.1));
            let min_distance = result.first().unwrap().1;
            result = result
                .iter()
                .filter(|(_, dist)| *dist == min_distance)
                .cloned()
                .collect();
            if result.len() == 1 {
                matrix.set(i, j, Some(result[0].0));
            }
        }
    }
    let p1_result = points
        .iter()
        .enumerate()
        .filter_map(|(i, p)| floodfill(&matrix, *p, i))
        .max()
        .unwrap();

    let p2_result = (0..max_row)
        .flat_map(|row| (0..max_col).map(move |col| (row, col)))
        .map(|p1| {
            points
                .iter()
                .map(move |p2| manhattan(p1, *p2))
                .sum::<usize>()
        })
        .filter(|res| *res < 10_000)
        .count();

    println!("Part 1: {}", p1_result);
    println!("Part 2: {}", p2_result);
    Ok(())
}
