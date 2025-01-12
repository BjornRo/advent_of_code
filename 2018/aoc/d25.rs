use std::collections::{HashMap, HashSet};
use std::fs;

type Point = Vec<isize>;

fn part1(points: &Vec<Point>) -> usize {
    let mut graph: HashMap<&Point, Vec<&Point>> = HashMap::new();
    for i in points {
        let mut neighbors = vec![];
        for j in points {
            if i != j {
                if i.iter().zip(j).fold(0, |acc, (a, b)| acc + (a - b).abs()) <= 3 {
                    neighbors.push(j);
                    graph.entry(j).or_insert_with(Vec::new).push(i);
                }
            }
        }
        graph.insert(i, neighbors);
    }

    let mut num_constellations: usize = 0;
    let mut visited: HashSet<&Point> = HashSet::new();
    for i in points {
        if visited.contains(&i) {
            continue;
        }
        let mut stack = vec![i];
        while let Some(point) = stack.pop() {
            if visited.contains(point) {
                continue;
            }
            visited.insert(point);
            stack.extend(graph.get(point).unwrap());
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
