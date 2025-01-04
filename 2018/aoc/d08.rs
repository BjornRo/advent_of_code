use std::fs;

type Index = usize;
type Sum = usize;

fn descender(
    list: &Vec<usize>,
    i: Index,
    mut p1_vec: Vec<Sum>,
    mut p2_vec: Vec<Sum>,
) -> (Index, Vec<Sum>, Vec<Sum>) {
    let [n_children, meta_len] = list[i..i + 2] else {
        panic!("nope")
    };

    if n_children == 0 {
        let child_end = i + 2 + meta_len;
        let value = list[i + 2..child_end].iter().sum();
        p1_vec.push(value);
        p2_vec.push(value);
        return (child_end, p1_vec, p2_vec);
    }

    let (next_i, acc_p1, acc_p2) = (0..n_children)
        .fold((i + 2, vec![], vec![]), |(i, acc_p1, acc_p2), _| {
            descender(list, i, acc_p1, acc_p2)
        });

    p1_vec.push(list[next_i..next_i + meta_len].iter().sum::<Sum>() + acc_p1.iter().sum::<Sum>());

    let root_sum: Sum = list[next_i..next_i + meta_len]
        .iter()
        .fold(0, |acc, x| acc + acc_p2.get(x - 1).unwrap_or(&0));
    p2_vec.push(root_sum);

    return (next_i + meta_len, p1_vec, p2_vec);
}

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d08.txt")?
        .trim_end()
        .split(" ")
        .map(|x| x.parse::<usize>().unwrap())
        .collect::<Vec<usize>>();

    let (_, p1, p2) = descender(&contents, 0, vec![], vec![]);
    println!("Part 1: {}", p1[0]);
    println!("Part 2: {}", p2[0]);
    Ok(())
}
