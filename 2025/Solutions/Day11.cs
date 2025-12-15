using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day11
{
    record Node(List<int> Parents, List<int> Children);
    static int Key(string value) => (value[0] << 16) | (value[1] << 8) | value[2];
    public static void Solve()
    {
        Dictionary<int, Node> graph = [];
        foreach (var line in File.ReadAllLines("in/d11.txt").Select(x => x.Split(": ")))
        {
            var left = Key(line[0]);
            graph.TryAdd(left, new Node([], []));
            foreach (var right in line[1].Split(" ").Select(Key))
            {
                graph.TryAdd(right, new Node([], []));
                graph[right].Parents.Add(left);
                graph[left].Children.Add(right);
            }
        }

        Console.WriteLine($"Part 1: {Part1(graph.ToImmutableDictionary(), Key("you"), Key("out"))}");
        Console.WriteLine($"Part 2: {Part2(graph.ToImmutableDictionary(), Key("svr"), Key("out"))}");
    }
    static int Part1(ImmutableDictionary<int, Node> graph, int node, int end) =>
        node == end ? 1 : graph[node].Children.Sum(child => Part1(graph, child, end));

    static long Part2(ImmutableDictionary<int, Node> graph, int start, int end)
    {
        long PathPlanner(int start, int end)
        {
            Dictionary<int, long> memo = [];
            long CountPaths(int node) => memo.TryGetValue(node, out var value)
                ? value : node == start
                ? memo[node] = 1 : memo[node] = graph[node].Parents.Sum(CountPaths);
            return CountPaths(end);
        }

        var DAC = Key("dac");
        var FFT = Key("fft");
        var (A0, A1) = (PathPlanner(start, FFT), PathPlanner(start, DAC));
        var (A, B, C) = A0 > A1 ? (A1, DAC, FFT) : (A0, FFT, DAC);
        return A * PathPlanner(B, C) * PathPlanner(C, end);
    }
}
