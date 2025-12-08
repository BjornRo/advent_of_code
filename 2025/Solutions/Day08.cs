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
    static (long, long) Solution(ImmutableArray<Junction> junctions, int nConnections)
    {
        long part1 = 0, part2 = 0;
        var graph = junctions.ToDictionary(j => j, _ => new HashSet<Junction>()); ;

        var iter_conns =
            junctions
                .SelectMany((a, i) => junctions.Skip(i + 1).Select(b => (a, b, a.Euclidean(b))))
                .OrderBy(x => x.Item3);
        foreach (var (i, a, b) in iter_conns.Select((x, i) => (i, x.a, x.b)))
        {
            graph[a].Add(b);
            graph[b].Add(a);
            if (i < nConnections - 1) continue;

            if (i == nConnections - 1)
            {
                part1 = graph.Keys
                    .Aggregate((List<HashSet<Junction>>)[], (list, node) =>
                            {
                                var result = Connectivity(graph, node, []);
                                if (!list.Any(s => s.SetEquals(result))) list.Add(result);
                                return list;
                            }
                        )
                    .OrderBy(h => -h.Count)
                    .Take(3)
                    .Aggregate(1, (prod, h) => prod * h.Count);
            }
            else if (i >= (nConnections * 2)) // optimization
            {
                if (Connectivity(graph, a, []).Count == nConnections)
                {
                    part2 = a.x * b.x;
                    break;
                }
            }
        }
        return (part1, part2);
    }
    static HashSet<Junction> Connectivity(
        Dictionary<Junction, HashSet<Junction>> graph,
        Junction node,
        HashSet<Junction> visited
    )
    {
        if (visited.Add(node)) foreach (var neighbor in graph[node]) Connectivity(graph, neighbor, visited);
        return visited;
    }
}
