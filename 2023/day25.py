import networkx as nx

with open("in/d25.txt") as f:
    conduct = {k: v.split(" ") for k, v in (x.rstrip().split(": ") for x in f)}

"""
Super general solution. Plot the graph, remove the nodes from the input.
"""

all_nodes = set(e for x in ((k, *v) for k, v in conduct.items()) for e in x)

G = nx.Graph()

for i in all_nodes:
    G.add_node(i)

for k, v in conduct.items():
    for n in v:
        G.add_edge(k, n)

a, b = list(map(len, nx.connected_components(G)))
print("Part 1:", a * b)
