using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day08
{
    readonly struct Junction(int id, in long x, long y, long z)
    {
        public readonly int id = id;
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

        public (Junction, Junction) Key(Junction o)
        {
            var a = this;
            var b = o;
            if (b.id < a.id) (a, b) = (b, a);
            return (a, b);
        }


        public void P()
        {
            Console.WriteLine($"{x},{y},{z}");
        }
        public string W()
        {
            return $"{x},{y},{z}";
        }
    }

    public static void Solve()
    {
        ImmutableArray<Junction> junctions = [.. File.ReadAllLines("in/d08.txt")
            .Select((x, index) => {
                var result = x.Split(",").Select(long.Parse).ToArray();
                return new Junction(index, result[0], result[1], result[2]);
            })
        ];

        var (p1, p2) = Solution(junctions, 1000);
        Console.WriteLine($"Part 1: {p1}");
        Console.WriteLine($"Part 2: {p2}");
    }

    static HashSet<Junction> Find(
    Dictionary<Junction, HashSet<Junction>> graph,
    Junction node,
    HashSet<Junction> visited
)
    {
        if (!visited.TryGetValue(node, out _))
        {
            visited.Add(node);
            foreach (var neighbor in graph[node]) Find(graph, neighbor, visited);
        }
        return visited;
    }
    static (long, long) Solution(ImmutableArray<Junction> junctions, int nConnections)
    {
        List<(Junction, Junction, double)> connections = [];

        for (int i = 0; i < junctions.Length - 1; i += 1)
            for (int j = i + 1; j < junctions.Length; j += 1)
                connections.Add((junctions[i], junctions[j], junctions[i].Euclidean(junctions[j])));

        connections.Sort((x, y) => x.Item3.CompareTo(y.Item3));

        long part1 = 0;

        Dictionary<Junction, HashSet<Junction>> graph = [];
        foreach (var (i, (a, b, _)) in connections.Select((x, index) => (index, x)))
        {
            if (!graph.TryGetValue(a, out _)) graph[a] = [];
            graph[a].Add(b);
            if (!graph.TryGetValue(b, out _)) graph[b] = [];
            graph[b].Add(a);

            if (i == nConnections - 1)
            {
                List<HashSet<Junction>> counts = [];
                foreach (var node in graph.Keys)
                {
                    var result = Find(graph, node, []);
                    bool equal = false;
                    foreach (var set in counts)
                    {
                        if (set.SetEquals(result))
                        {
                            equal = true;
                            break;
                        }
                    }
                    if (!equal) counts.Add(result);
                }
                List<int> values = [.. counts.Select(x => x.Count)];
                values.Sort();
                part1 = values[^3] * values[^2] * values[^1];
            }
            else if (i >= (nConnections * 2) && Find(graph, a, []).Count == nConnections)
            {
                return (part1, a.x * b.x);
            }
        }

        return (0, 0);
    }
}
