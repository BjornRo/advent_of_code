use rayon::prelude::*;
use std::fs;

const DIMENSION: usize = 300;
type Matrix = [[isize; DIMENSION]; DIMENSION];

fn scanner(matrix: &Matrix, kernel_size: usize) -> (isize, (usize, usize)) {
    let mut max_power: isize = 0;
    let mut coord: (usize, usize) = (0, 0);

    for x in 0..=DIMENSION - kernel_size {
        for y in 0..=DIMENSION - kernel_size {
            let mut total_power = 0 as isize;
            for xk in x..x + kernel_size {
                for yk in y..y + kernel_size {
                    total_power += matrix[xk][yk];
                }
            }
            if total_power > max_power {
                max_power = total_power;
                coord = (x, y);
            }
        }
    }
    (max_power, (coord.0, coord.1))
}

fn part2(matrix: &Matrix) -> ((usize, usize), usize) {
    let results: Vec<(isize, (usize, usize), usize)> = (1..=DIMENSION)
        .into_par_iter()
        .map(|k| {
            let (power, c) = scanner(matrix, k);
            (power, c, k)
        })
        .collect();

    let mut max_power: isize = 0;
    let mut best_kernel: usize = 0;
    let mut coord: (usize, usize) = (0, 0);
    for (power, c, k) in results {
        if power > max_power {
            max_power = power;
            best_kernel = k;
            coord = c;
        }
    }
    (coord, best_kernel)
}
fn main() -> std::io::Result<()> {
    let serial_num: usize = fs::read_to_string("in/d11.txt")?
        .trim_end()
        .parse()
        .unwrap();

    let mut matrix: Matrix = [[0; DIMENSION]; DIMENSION];
    for x in 0..DIMENSION {
        for y in 0..DIMENSION {
            let rack_id = x + 10;
            let power_level = rack_id * y + serial_num;
            let fuel_cell = (((power_level * rack_id) / 100) % 10) as isize - 5;
            matrix[x][y] = fuel_cell;
        }
    }

    let (_, (p1x, p1y)) = scanner(&matrix, 3);
    let ((p2x, p2y), kernel) = part2(&matrix);

    println!("Part 1: {},{}", p1x, p1y);
    println!("Part 2: {},{},{}", p2x, p2y, kernel);
    Ok(())
}

// fn part2(matrix: &Matrix) -> ((usize, usize), usize) {
//     let mut max_power: isize = 0;
//     let mut best_kernel: usize = 0;
//     let mut coord: (usize, usize) = (0, 0);

//     let results: Vec<(isize, (usize, usize), usize)> = (1..=DIMENSION)
//         .into_par_iter()
//         .map(|k| {
//             let (power, c) = scanner(matrix, k);
//             (power, c, k)
//         })
//         .collect();
//     println!("{:?}", results);

//     (coord, best_kernel)
// }
