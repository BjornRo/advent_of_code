from collections import defaultdict

with open("in/d07.txt") as f:
    data = tuple(x.rstrip().replace(",", "").split(" ") for x in f)

type Graph = dict[str, list[str]]

weights: dict[str, int] = {}
graph: Graph = defaultdict(list)
all_children = set()
for d in data:
    match d:
        case uid, val:
            weights[uid] = int(val[1:][:-1])
        case uid, val, "->", *xs:
            weights[uid] = int(val[1:][:-1])
            for x in xs:
                graph[uid].append(x)
                all_children.add(x)


def part2(graph: Graph, weights: dict[str, int], bottom_key: str):
    def anomaly(graph: Graph, weights: dict[str, int], key: str, result: list[int]):
        if not graph[key]:
            return weights[key]

        child_weights = [anomaly(graph, weights, child, result) for child in graph[key]]
        cmin = min(child_weights)
        cmax = max(child_weights)
        if cmin != cmax:
            result.append(weights[graph[key][child_weights.index(cmax)]] - abs(cmin - cmax))
        return sum(child_weights) + weights[key]

    res = []
    anomaly(graph, weights, bottom_key, res)
    return res[0]


bottom_key = (set(graph) - all_children).pop()
print(f"Part 1: {bottom_key}")
print(f"Part 2: {part2(graph, weights, bottom_key)}")
