use std::fs;

fn solver(mut recipes: Vec<u8>, input_vec: Vec<u8>) -> (String, usize) {
    let p1_target = input_vec
        .iter()
        .fold(0, |acc, &digit| acc * 10 + digit as usize);
    let mut p1_result: Option<String> = None;

    let mut e1_i = 0;
    let mut e2_i = 1;
    let mut scan_idx: usize = 0;

    loop {
        let sum: u8 = recipes[e1_i] + recipes[e2_i];
        recipes.extend(
            (0..(sum as f64).log10() as usize + 1)
                .scan(sum, |state, _| {
                    let digit = *state % 10;
                    *state /= 10;
                    Some(digit)
                })
                .collect::<Vec<u8>>()
                .into_iter()
                .rev(),
        );

        e1_i = (e1_i + 1 + recipes[e1_i] as usize) % recipes.len();
        e2_i = (e2_i + 1 + recipes[e2_i] as usize) % recipes.len();
        if recipes.len() >= input_vec.len() {
            while recipes.len() - input_vec.len() != scan_idx {
                if recipes[scan_idx..scan_idx + input_vec.len()] == input_vec {
                    return (p1_result.unwrap(), recipes[0..scan_idx].iter().count());
                }
                scan_idx += 1;
            }
        }
        if p1_result == None && recipes.len() >= p1_target + 10 {
            p1_result = Some(
                recipes[p1_target..p1_target + 10]
                    .iter()
                    .map(|&digit| digit.to_string())
                    .collect::<Vec<String>>()
                    .join(""),
            );
        }
    }
}

fn main() -> std::io::Result<()> {
    let input_vec: Vec<u8> = fs::read_to_string("in/d14.txt")?
        .trim_end()
        .chars()
        .map(|c| (c as u8 - '0' as u8) as u8)
        .collect();

    let (p1, p2) = solver(vec![3, 7], input_vec);

    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
