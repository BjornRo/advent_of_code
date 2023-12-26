from collections import defaultdict, deque

# Does not work on test input :), Gives same result as networkx below
graph, count_crossings = defaultdict(list), defaultdict(int)
with open("in/d25.txt") as f:
    for e1, v in (x.rstrip().split(": ") for x in f):
        for e2 in v.split():
            graph[e1].append(e2)
            graph[e2].append(e1)


def dfs():  # Mutates graph, so it cannot be re-used after.
    visited, queue = set(), deque()
    for ignore in (False, True):
        for k in graph:
            visited.add(k)
            queue.append(k)
            while queue:
                node = queue.popleft()
                for next_node in graph[node]:
                    if next_node not in visited:
                        visited.add(next_node)
                        queue.append(next_node)
                        if not ignore:
                            count_crossings[tuple(sorted((node, next_node)))] += 1
            if ignore:
                return (len(graph) - len(visited)) * len(visited)
            visited.clear()
        for (e1, e2), _ in sorted(count_crossings.items(), key=lambda x: x[1])[-3:]:
            graph[e1].remove(e2)
            graph[e2].remove(e1)


print("Part 1:", dfs())


# import networkx as nx

# G = nx.Graph()
# with open("in/d25.txt") as f:
#     for e1, v in (x.rstrip().split(": ") for x in f):
#         for e2 in v.split(" "):
#             G.add_edge(e1, e2)

# G.remove_edges_from(nx.minimum_edge_cut(G))
# print("Part 1:", eval("*".join(map(str, map(len, nx.connected_components(G))))))
