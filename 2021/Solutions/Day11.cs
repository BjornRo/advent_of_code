namespace aoc.Solutions;

public class Day11
{
    public static void Solve()
    {
        var grid = File.ReadAllLines("in/d11.txt")
            .Select(l => l.Select(c => (byte)(c - '0')).ToArray())
            .ToArray();

        var (p1, p2) = Solve(grid);
        Console.WriteLine($"Part 1: {p1}");
        Console.WriteLine($"Part 2: {p2}");
    }
    static IEnumerable<(int, int)> Kernel3(byte[][] matrix, int row, int col)
    {
        for (int i = -1; i < 2; i++)
            for (int j = -1; j < 2; j++)
                if (i != 0 || j != 0)
                {
                    var (dr, dc) = (row + i, col + j);
                    if (0 <= dr && dr < matrix.Length && 0 <= dc && dc < matrix[0].Length)
                        yield return (dr, dc);
                }
    }
    static (long, long) Solve(byte[][] grid)
    {
        List<(int, int)> flashed = new(100);
        void Flash(int row, int col)
        {
            grid[row][col] += 1;
            if (grid[row][col] == 10)
            {
                flashed.Add((row, col));
                foreach (var (dr, dc) in Kernel3(grid, row, col))
                    Flash(dr, dc);
            }
        }
        var totalElems = grid.Length * grid[0].Length;
        long total = 0;
        foreach (var k in Enumerable.Range(1, int.MaxValue))
        {
            for (int i = 0; i < grid.Length; i++)
                for (int j = 0; j < grid[0].Length; j++) Flash(i, j);

            if (k <= 100) total += flashed.Count;
            if (flashed.Count == totalElems) return (total, k);

            foreach (var (row, col) in flashed) grid[row][col] = 0;
            flashed.Clear();
        }
        return (0, 0);
    }
}
