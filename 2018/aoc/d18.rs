use std::{collections::HashMap, fs};

const KERNEL: [(i8, i8); 8] = [
    (1, 0),
    (0, 1),
    (-1, 0),
    (0, -1),
    (1, 1),
    (1, -1),
    (-1, -1),
    (-1, 1),
];

fn offset_add(row: usize, col: usize, (r, c): (i8, i8), dim: i8) -> Option<(usize, usize)> {
    let (nr, nc) = (row as i8 + r, col as i8 + c);
    if 0 <= nr && nr < dim && 0 <= nc && nc < dim {
        Some((nr as usize, nc as usize))
    } else {
        None
    }
}

fn segregation(mut grid: Vec<Vec<char>>) -> (usize, usize) {
    let three_adj = |g: &Vec<Vec<char>>, i: usize, j: usize, symbol: char| {
        KERNEL
            .iter()
            .filter_map(|&d| offset_add(i, j, d, g.len() as i8))
            .fold(0, |acc, (r, c)| acc + (g[r][c] == symbol) as u8)
            >= 3
    };
    let mut tmp_grid = grid.clone();

    let mut map: HashMap<String, usize> = HashMap::new();
    let mut map_value: HashMap<usize, usize> = HashMap::new();

    let mut p1_result: usize = 0;
    let mut p2_result: usize = 0;
    for m in 0..1000000000 {
        for i in 0..grid.len() {
            for j in 0..grid[0].len() {
                let symbol = match grid[i][j] {
                    '.' => '|',
                    '|' => '#',
                    '#' => '.',
                    _ => panic!(),
                };
                if symbol == '.' {
                    let result = KERNEL
                        .iter()
                        .filter_map(|&d| offset_add(i, j, d, grid.len() as i8))
                        .fold((false, false), |(lumberyard, tree), (r, c)| {
                            match grid[r][c] {
                                '#' => (true, tree),
                                '|' => (lumberyard, true),
                                _ => (lumberyard, tree),
                            }
                        });
                    if result == (true, true) {
                        continue;
                    }
                } else {
                    if !three_adj(&grid, i, j, symbol) {
                        continue;
                    }
                }
                tmp_grid[i][j] = symbol;
            }
        }
        grid = tmp_grid.clone();

        let (trees, lumberyards) =
            grid.iter()
                .flat_map(|row| row.iter())
                .fold((0, 0), |(tree, lumberyard), c| match c {
                    '#' => (tree, lumberyard + 1),
                    '|' => (tree + 1, lumberyard),
                    _ => (tree, lumberyard),
                });

        if p1_result == 0 && m == 9 {
            p1_result = trees * lumberyards;
        }

        map_value.insert(m, trees * lumberyards);
        let key: String = grid.iter().flat_map(|row| row.iter()).collect();
        let idx = *map.entry(key).or_insert(m);
        if idx != m {
            let calc_index = ((1_000_000_000 - idx) % (m - idx)) + idx - 1;
            p2_result = *map_value.get(&calc_index).unwrap();
            break;
        }
    }
    (p1_result, p2_result)
}

fn main() -> std::io::Result<()> {
    let matrix: Vec<Vec<char>> = fs::read_to_string("in/d18.txt")?
        .trim_end()
        .lines()
        .map(|row| row.chars().collect())
        .collect();

    let (p1, p2) = segregation(matrix);
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
