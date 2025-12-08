using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day08
{
    readonly struct Junction(in long x, long y, long z)
    {
        public readonly long x = x;
        public readonly long y = y;
        public readonly long z = z;

        public double Euclidean(Junction o)
        {
            long dx = o.x - x;
            long dy = o.y - y;
            long dz = o.z - z;

            return Math.Sqrt(dx * dx + dy * dy + dz * dz);
        }
    }

    public static void Solve()
    {
        ImmutableArray<Junction> junctions = [.. File.ReadAllLines("in/d08.txt")
            .Select((x, index) => {
                var result = x.Split(",").Select(long.Parse).ToArray();
                return new Junction(result[0], result[1], result[2]);
            })
        ];

        var (p1, p2) = Solution(junctions, 1000);
        Console.WriteLine($"Part 1: {p1}");
        Console.WriteLine($"Part 2: {p2}");
    }

    static HashSet<Junction> Connectivity(
    Dictionary<Junction, HashSet<Junction>> graph,
    Junction node,
    HashSet<Junction> visited
)
    {
        if (!visited.TryGetValue(node, out _))
        {
            visited.Add(node);
            foreach (var neighbor in graph[node]) Connectivity(graph, neighbor, visited);
        }
        return visited;
    }
    static (long, long) Solution(ImmutableArray<Junction> junctions, int nConnections)
    {
        List<(Junction, Junction, double)> connections = [];
        foreach (var (i, a) in junctions[..^1].Select((e, i) => (i, e)))
            foreach (var b in junctions[(i + 1)..])
                connections.Add((a, b, a.Euclidean(b)));

        connections.Sort((x, y) => x.Item3.CompareTo(y.Item3));

        long part1 = 0, part2 = 0;
        var graph = junctions.ToDictionary(j => j, _ => new HashSet<Junction>()); ;
        foreach (var (i, (a, b, _)) in connections.Select((x, index) => (index, x)))
        {
            graph[a].Add(b);
            graph[b].Add(a);
            if (i < nConnections - 1) continue;

            if (i == nConnections - 1)
            {
                List<HashSet<Junction>> counts = [];
                foreach (var node in graph.Keys)
                {
                    var result = Connectivity(graph, node, []);
                    if (!counts.Any(s => s.SetEquals(result)))
                        counts.Add(result);
                }
                counts.Sort((x, y) => y.Count.CompareTo(x.Count));
                part1 = counts.Take(3).Aggregate(1, (prod, x) => prod * x.Count);
            }
            else if (i >= (nConnections * 2) && Connectivity(graph, a, []).Count == nConnections)
            {
                part2 = a.x * b.x;
                break;
            }
        }
        return (part1, part2);
    }
}
