struct Node {
    position: Position,
    g_cost: u8,
    h_cost: u8,
}
impl Node {
    fn f_cost(&self) -> u8 {
        self.g_cost + self.h_cost
    }
}

fn a_star(
    start: Position,
    target: Position,
    grid: &Vec<Vec<bool>>,
    unit_positions: &HashSet<Position>,
) -> Option<(u8, Position)> {
    // Option<(u8, Vec<Position>)>
    fn manhattan_distance(a: Position, b: Position) -> u8 {
        ((a.0 - b.0).abs() + (a.1 - b.1).abs()) as u8
    }

    let mut open_set = BinaryHeap::new();
    // let mut came_from: HashMap<Position, Position> = HashMap::new();
    let mut first_step: Option<Position> = None;
    let mut g_costs: HashMap<Position, u8> = HashMap::new();

    let start_node = Node {
        position: start,
        g_cost: 0,
        h_cost: manhattan_distance(start, target),
    };
    open_set.push(start_node);

    while let Some(node) = open_set.pop() {
        if node.position == target {
            // let mut path = vec![node.position];
            // while let Some(prev_pos) = came_from.get(&path.last().unwrap().clone()) {
            //     path.push(*prev_pos);
            //     println!("{:?}", prev_pos);
            // }
            // path.reverse();
            // return Some((node.g_cost, path));
            return Some((node.g_cost, first_step.unwrap()));
        }

        for (dr, dc) in OFFSETS {
            let np @ (nr, nc) = (node.position.0 + dr, node.position.1 + dc);
            if grid[nr as usize][nc as usize] && !unit_positions.contains(&np) {
                let g_cost = node.g_cost + if dr == 0 { 1 } else { 1 };
                let h_cost = manhattan_distance(np, target);

                if let Some(&existing_g_cost) = g_costs.get(&np) {
                    if g_cost >= existing_g_cost {
                        continue;
                    }
                }
                g_costs.insert(np, g_cost);
                let next_node = Node {
                    position: np,
                    g_cost,
                    h_cost,
                };
                open_set.push(next_node);
                // came_from.insert(np, node.position);
            }
        }
        if first_step == None {
            if let Some(pos) = open_set.peek() {
                let (nr, nc) = pos.position;
                let (r, c) = node.position;
                first_step = Some((nr - r, nc - c));
            }
        }
    }
    None
}
fn dijkstra(
    start: Position,
    target: Position,
    grid: &Vec<Vec<bool>>,
    unit_positions: &HashSet<Position>,
) -> HashMap<Position, u8> {
    let mut costs: HashMap<Position, u8> = HashMap::new();
    let mut visited: HashSet<Position> = HashSet::new();
    let mut heap = BinaryHeap::new();

    costs.insert(start, 0);
    heap.push(Node {
        position: start,
        cost: 0,
    });

    while let Some(node) = heap.pop() {
        if node.position == target {
            break;
        }
        if visited.contains(&node.position) {
            continue;
        }
        visited.insert(node.position);
        for (dr, dc) in OFFSETS {
            let np @ (nr, nc) = (node.position.0 + dr, node.position.1 + dc);
            if grid[nr as usize][nc as usize] && !unit_positions.contains(&np) {
                let new_cost = node.cost + 1;
                let entry = costs.entry(np).or_insert(u8::MAX);

                if new_cost < *entry {
                    *entry = new_cost;
                    heap.push(Node {
                        position: np,
                        cost: new_cost,
                    });
                }
            }
        }
    }
    costs
}
#[derive(Clone, Copy, PartialEq, Eq, Hash, Debug)]
struct Node {
    position: Position,
    cost: u8,
}
impl Node {
    fn f_cost(&self) -> u8 {
        self.cost
    }
}
impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        other.f_cost().cmp(&self.f_cost())
    }
}
impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}
type Position = (i8, i8);
const OFFSETS: [Position; 4] = [(1, 0), (0, 1), (-1, 0), (0, -1)];