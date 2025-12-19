using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day12
{
    public static void Solve()
    {
        var lines = File.ReadAllLines("in/d12.txt").Select(l => l.Split('-'));

        var keys = lines
            .SelectMany(p => p)
            .Distinct()
            .OrderBy(s => s == "start" ? 0 : s == "end" ? 2 : 1)
            .Select((s, i) => (s, i))
            .ToImmutableDictionary(x => x.s, x => (ushort)x.i);

        var graph = lines
            .SelectMany(p => new[] { (From: keys[p[0]], To: keys[p[1]]), (From: keys[p[1]], To: keys[p[0]]) })
            .GroupBy(e => e.From, e => e.To)
            .ToImmutableDictionary(g => (ushort)(1 << g.Key), g => g.Select(x => (ushort)(1 << x)).ToImmutableArray());

        ushort smallCaves = (ushort)keys
            .Where(kv => kv.Key != "start" && kv.Key != "end" && kv.Key.All(char.IsLower))
            .Aggregate(0, (mask, kv) => mask | (1 << kv.Value));

        Console.WriteLine($"Part 1: {Part1(graph, smallCaves)}");
        Console.WriteLine($"Part 2: {Part2(graph, smallCaves)}");
    }
    static int Part1(ImmutableDictionary<ushort, ImmutableArray<ushort>> graph, ushort smallCaves)
    {
        var end = (ushort)(1 << graph.Count - 1);
        int paths = 0;
        Stack<(ushort, ushort)> stack = new([(1 << 0, 0)]);
        while (stack.TryPop(out var state))
        {
            var (node, visited) = state;
            if (node == end)
            {
                paths += 1;
                continue;
            }
            if ((smallCaves & node) != 0)
            {
                if ((visited & node) != 0) continue;
                visited |= node;
            }
            foreach (var neighbor in graph[node].Where(x => x != (1 << 0)))
                stack.Push((neighbor, visited));
        }
        return paths;
    }
    static int Part2(ImmutableDictionary<ushort, ImmutableArray<ushort>> graph, ushort smallCaves)
    {
        var end = (ushort)(1 << graph.Count - 1);
        int paths = 0;
        Stack<(ushort, ushort, bool)> stack = new([(1 << 0, 0, false)]);
        while (stack.TryPop(out var state))
        {
            var (node, visited, secondVisit) = state;
            if (node == end)
            {
                paths += 1;
                continue;
            }
            if ((smallCaves & node) != 0)
            {
                if ((visited & node) != 0)
                {
                    if (secondVisit) continue;
                    secondVisit = true;
                }
                visited |= node;
            }
            foreach (var neighbor in graph[node].Where(x => x != (1 << 0)))
                stack.Push((neighbor, visited, secondVisit));
        }
        return paths;
    }
}