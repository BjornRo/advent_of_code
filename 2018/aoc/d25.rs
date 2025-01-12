use std::collections::{HashMap, HashSet};
use std::fs;

type Point = Vec<isize>;

fn part1(points: &Vec<Point>) -> usize {
    let mut graph: HashMap<usize, Vec<usize>> = HashMap::new();
    for (i, ii) in points.iter().enumerate() {
        let mut neighbors = vec![];
        for (j, jj) in points.iter().enumerate() {
            if i != j {
                if ii.iter().zip(jj).fold(0, |acc, (a, b)| acc + (a - b).abs()) <= 3 {
                    neighbors.push(j);
                    graph.entry(j).or_insert_with(Vec::new).push(i);
                }
            }
        }
        graph.insert(i, neighbors);
    }

    let mut num_constellations: usize = 0;
    let mut visited: HashSet<usize> = HashSet::new();
    for id in 0..points.len() {
        if visited.contains(&id) {
            continue;
        }
        let mut stack = vec![id];
        while let Some(id) = stack.pop() {
            if visited.contains(&id) {
                continue;
            }
            visited.insert(id);
            stack.extend(graph.get(&id).unwrap());
        }
        num_constellations += 1;
    }
    num_constellations
}

fn main() -> std::io::Result<()> {
    let data: Vec<Vec<isize>> = fs::read_to_string("in/d25.txt")?
        .trim_end()
        .lines()
        .map(|line| line.split(",").map(|x| x.parse().unwrap()).collect())
        .collect();

    println!("Part 1: {}", part1(&data));
    Ok(())
}
