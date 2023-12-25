import networkx as nx

G = nx.Graph()
with open("in/d25.txt") as f:
    for e1, v in (x.rstrip().split(": ") for x in f):
        for e2 in v.split(" "):
            G.add_edge(e1, e2)

G.remove_edges_from(nx.minimum_edge_cut(G))
print("Part 1:", eval("*".join(map(str, map(len, nx.connected_components(G))))))
