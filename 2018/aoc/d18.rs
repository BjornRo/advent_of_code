use std::{collections::HashMap, fs};
use GridTypes::*;

#[derive(Debug, Hash, Eq, PartialEq, Clone)]
enum GridTypes {
    Open,
    Tree,
    Lumberyard,
}

impl From<char> for GridTypes {
    fn from(c: char) -> Self {
        match c {
            '.' => GridTypes::Open,
            '|' => GridTypes::Tree,
            '#' => GridTypes::Lumberyard,
            _ => panic!(),
        }
    }
}

fn accumulator(g: &Vec<Vec<GridTypes>>, i: usize, j: usize) -> (usize, usize) {
    #[rustfmt::skip]
    const KERNEL: [(i8, i8); 8] = [(1, 0), (0, 1), (-1, 0), (0, -1), (1, 1),(1, -1), (-1, -1),(-1, 1)];
    KERNEL
        .iter()
        .filter_map(|&(r, c)| {
            let (nr, nc) = (i as i8 + r, j as i8 + c);
            if 0 <= nr && nr < g.len() as i8 && 0 <= nc && nc < g.len() as i8 {
                return Some((nr as usize, nc as usize));
            }
            None
        })
        .fold((0, 0), |(trees, lumberyard), (r, c)| match g[r][c] {
            Open => (trees, lumberyard),
            Tree => (trees + 1, lumberyard),
            Lumberyard => (trees, lumberyard + 1),
        })
}

fn segregation(mut grid: Vec<Vec<GridTypes>>) -> (usize, usize) {
    let mut index: usize = 0;

    let mut map: HashMap<Vec<Vec<GridTypes>>, usize> = HashMap::new();
    let mut map_value: Vec<usize> = vec![];
    loop {
        let (mut n_trees, mut n_lumberyards) = (0, 0);
        grid = grid
            .iter()
            .enumerate()
            .map(|(i, row)| {
                row.iter()
                    .enumerate()
                    .map({
                        let grid = &grid;
                        move |(j, c)| {
                            let (trees, lumberyards) = accumulator(&grid, i, j);
                            match c {
                                Open if trees >= 3 => Tree,
                                Tree if lumberyards >= 3 => Lumberyard,
                                Lumberyard if lumberyards < 1 || trees < 1 => Open,
                                _ => c.clone(),
                            }
                        }
                    })
                    .inspect(|c| match c {
                        Tree => n_trees += 1,
                        Lumberyard => n_lumberyards += 1,
                        _ => {}
                    })
                    .collect()
            })
            .collect();

        map_value.push(n_trees * n_lumberyards);
        let map_index = *map.entry(grid.clone()).or_insert(index);
        if map_index != index {
            let calc_index = ((1_000_000_000 - map_index) % (index - map_index)) + map_index - 1;
            return (map_value[9], map_value[calc_index]);
        }
        index += 1;
    }
}

fn main() -> std::io::Result<()> {
    let matrix: Vec<Vec<GridTypes>> = fs::read_to_string("in/d18.txt")?
        .trim_end()
        .lines()
        .map(|row| row.chars().map(|c| c.into()).collect())
        .collect();

    let (p1, p2) = segregation(matrix);
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
