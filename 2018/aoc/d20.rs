use std::cmp::max;
use std::collections::{HashMap, HashSet, VecDeque};
use std::fs;

type Pos = (isize, isize);
type Graph = HashMap<Pos, Vec<Pos>>;

struct State {
    pos: Pos,
    steps: usize,
    visited: HashSet<Pos>,
}

impl State {
    fn new(pos: Pos, steps: usize, visited: HashSet<Pos>) -> Self {
        State {
            pos,
            steps,
            visited,
        }
    }
    fn get(&mut self) -> (Pos, usize, &mut HashSet<Pos>) {
        (self.pos, self.steps, &mut self.visited)
    }
}

fn door_frames(string: &Vec<char>, graph: &mut Graph, mut index: usize, mut pos: Pos) -> usize {
    loop {
        match string[index] {
            '|' | ')' | '$' => break,
            '(' => {
                while string[index] != ')' {
                    index = door_frames(string, graph, index + 1, pos);
                }
            }
            c => {
                let next_pos = match c {
                    'N' => (pos.0 - 1, pos.1),
                    'S' => (pos.0 + 1, pos.1),
                    'E' => (pos.0, pos.1 + 1),
                    _w => (pos.0, pos.1 - 1),
                };
                graph.entry(pos).or_insert_with(Vec::new).push(next_pos);
                pos = next_pos
            }
        };
        index += 1;
    }
    index
}

fn house_of_doors(graph: &Graph, start_pos: Pos) -> (usize, usize) {
    let mut doors_1k: HashMap<Pos, usize> = HashMap::new();
    let mut max_doors: usize = 0;

    let mut queue: VecDeque<State> = vec![State::new(start_pos, 0, HashSet::new())].into();
    while let Some(mut state) = queue.pop_front() {
        let (pos, steps, visited) = state.get();
        if visited.contains(&pos) {
            max_doors = max(max_doors, steps - 1);
            continue;
        }
        doors_1k.insert(pos, steps);
        visited.insert(pos);

        for next_pos in graph.get(&pos).unwrap_or(&vec![]) {
            queue.push_back(State::new(*next_pos, steps + 1, visited.clone()));
        }
    }
    (max_doors, doors_1k.values().filter(|&&x| x >= 1000).count())
}

fn main() -> std::io::Result<()> {
    let string: Vec<char> = fs::read_to_string("in/d20.txt")?
        .trim_end()
        .chars()
        .collect();

    let mut graph: Graph = HashMap::new();
    door_frames(&string, &mut graph, 1, (0, 0));
    let (p1, p2) = house_of_doors(&graph, (0, 0));
    println!("Part 1: {}", p1);
    println!("Part 2: {}", p2);
    Ok(())
}
