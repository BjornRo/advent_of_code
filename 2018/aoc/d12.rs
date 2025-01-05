use std::fs;

fn str_to_u8(s: &str) -> u8 {
    s.chars()
        .rev()
        .map(|c| (c == '#') as u8)
        .enumerate()
        .fold(0, |acc, (i, c)| acc | (c << i))
}

fn solver(mut state: Vec<u8>, map: &[u8; 32], iterations: u64, sensitivity: u8) -> (isize, isize) {
    let mut next_state: Vec<u8> = vec![];
    let mut p1: isize = 0;

    // For p2
    let mut last_value: isize = 0;
    let mut last_delta: isize = 0;
    // If there are false positives before convergence
    let mut threshold: usize = sensitivity.into();

    let mut offset: isize = 0;
    for i in 0..iterations {
        next_state.clear();

        let mut one = false;
        let mut plot: usize = 0;
        for j in 0..state.len() {
            plot |= state[j] as usize;
            let result = map[plot];
            if !one {
                if result == 1 {
                    offset += j as isize - 2;
                    one = true;
                    next_state.push(result);
                }
            } else {
                next_state.push(result);
            }
            plot <<= 1;
            plot &= 31; // Keep only 5 digits
        }
        // Push out the last bits
        for _ in 0..3 {
            next_state.push(map[plot]);
            plot <<= 1;
            plot &= 31;
        }
        state = next_state[0..next_state.iter().rposition(|&x| x == 1).unwrap() + 1].to_vec();
        let result: isize = state
            .iter()
            .enumerate()
            .map(|(i, &e)| if e == 1 { i as isize + offset } else { 0 })
            .sum();
        let delta = result - last_value;
        if delta == last_delta {
            threshold -= 1;
            if threshold == 0 {
                let p2 = result + (iterations - i - 1) as isize * delta;
                return (p1, p2);
            }
        } else {
            threshold = sensitivity.into();
        }

        last_value = result;
        last_delta = delta;
        if i == 19 {
            p1 = result;
        }
    }
    panic!("Not here!");
}

fn main() -> std::io::Result<()> {
    let binding = fs::read_to_string("in/d12.txt")?;
    let (state, mappings) = binding.trim_end().split_once("\n\n").unwrap();

    let init_state: Vec<u8> = state
        .trim_end()
        .split(" ")
        .nth(2)
        .unwrap()
        .chars()
        .map(|c| (c == '#') as u8)
        .collect();

    let mut map = [0 as u8; 32];
    mappings.split("\n").for_each(|r| {
        let (a, b) = r.split_once(" => ").unwrap();
        map[str_to_u8(a) as usize] = (b == "#") as u8;
    });

    let (p1, p2) = solver(init_state, &map, 50000000000, 2);
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
