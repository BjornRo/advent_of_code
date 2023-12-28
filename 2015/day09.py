from collections import defaultdict

graph = defaultdict(dict)
with open("in/d9.txt") as f:
    for toto, weight in (x.rstrip().split(" = ") for x in f):
        (src, dst), weight = toto.split(" to "), int(weight)
        graph[src][dst] = weight
        graph[dst][src] = weight


def galaxytrotter(graph: dict[str, dict[str, int]], max_min):
    all_places, stack, route_length = set(graph), [], float("inf") if max_min.__name__ == "min" else 0
    for place in graph:
        if place not in graph:
            continue
        stack.append((place, set(), 0))
        while stack:
            place, visited, cost = stack.pop()
            if place in visited:
                continue
            visited.add(place)
            if visited == all_places:
                route_length = max_min(route_length, cost)
                continue
            for next_place, weight in graph[place].items():
                stack.append((next_place, visited.copy(), weight + cost))
    return route_length


print("Part 1:", galaxytrotter(graph, min))
print("Part 2:", galaxytrotter(graph, max))
