using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day15
{
    static ImmutableArray<ImmutableArray<byte>> GenGridP2(ImmutableArray<ImmutableArray<byte>> grid)
    {
        static byte MaxNine(int value) => (byte)(value >= 10 ? value % 9 : value);
        var matrix = new byte[grid.Length * 5][];
        for (int i = 0; i < matrix.Length; i++) matrix[i] = new byte[grid[0].Length * 5];
        for (int i = 0; i < 5; i++)
            for (int row = 0; row < grid.Length; row++)
                for (int col = 0; col < grid[0].Length; col++)
                    matrix[i * grid.Length + row][col] = MaxNine(grid[row][col] + i);
        for (int i = 1; i < 5; i++)
            for (int row = 0; row < matrix.Length; row++)
                for (int col = 0; col < grid[0].Length; col++)
                    matrix[row][i * grid[0].Length + col] = MaxNine(matrix[row][col] + i);
        return [.. matrix.Select(x => x.ToImmutableArray())];
    }
    public static void Solve()
    {
        var grid = File.ReadAllLines("in/d15.txt")
            .Select(l => l.Select(c => (byte)(c - '0')).ToImmutableArray())
            .ToImmutableArray();

        Console.WriteLine($"Part 1: {Dijkstra(grid)}");
        Console.WriteLine($"Part 2: {Dijkstra(GenGridP2(grid))}");
    }
    static int Dijkstra(ImmutableArray<ImmutableArray<byte>> grid)
    {
        var end = (grid.Length - 1, grid[0].Length - 1);
        var minCost = int.MaxValue;
        var queue = new PriorityQueue<(int r, int c), int>([((0, 0), 0)]);
        HashSet<(int, int)> visited = [];
        while (queue.TryDequeue(out var pos, out var cost))
        {
            if (pos == end)
            {
                if (cost < minCost) minCost = cost;
                continue;
            }
            if (cost >= minCost) continue;
            if (!visited.Add(pos)) continue;
            foreach (var (dr, dc) in Utils.Cross3Filter(grid.Length, grid[0].Length, pos.r, pos.c))
                queue.Enqueue((dr, dc), cost + grid[dr][dc]);
        }
        return minCost;
    }
}
