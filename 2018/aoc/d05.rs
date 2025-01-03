use std::fs;

fn process_data(mut data: Vec<char>) -> usize {
    let mut tmp: Vec<char> = vec![];

    loop {
        tmp.clear();
        let mut i = 0 as usize;

        while i < data.len() {
            if i + 1 != data.len() {
                if data[i].to_ascii_lowercase() == data[i + 1].to_ascii_lowercase() {
                    if data[i] != data[i + 1] {
                        i += 2;
                        continue;
                    }
                }
            }
            tmp.push(data[i]);
            i += 1;
        }
        let last_size = data.len();
        data = tmp.clone();
        if tmp.len() == last_size {
            return tmp.len();
        }
    }
}

fn main() -> std::io::Result<()> {
    let contents: Vec<char> = fs::read_to_string("in/d05.txt")?
        .trim_end()
        .chars()
        .collect();

    let p2_res = ('a'..='z')
        .map(|c| {
            let data: Vec<char> = contents
                .iter()
                .filter(|v| v.to_ascii_lowercase() != c)
                .cloned()
                .collect();
            process_data(data)
        })
        .min()
        .unwrap();

    println!("Part 1: {}", process_data(contents));
    println!("Part 2: {}", p2_res);
    Ok(())
}
