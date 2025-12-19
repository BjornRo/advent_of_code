namespace aoc.Solutions;

public class Day09
{
    record Point(int Row, int Col);
    public static void Solve()
    {
        var matrix = File.ReadAllLines("in/d09.txt")
            .Select(x => x.ToCharArray().Select(y => (byte)(y - '0')).ToArray())
            .ToArray();

        Console.WriteLine($"Part 1: {Part1(matrix).Values.Sum()}");
        Console.WriteLine($"Part 2: {Part2(matrix)}");
    }
    static IEnumerable<(int, int)> Kernel3(byte[][] matrix, int row, int col)
    {
        foreach (var (dr, dc) in new[] { (row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1) })
            if (0 <= dr && dr < matrix.Length && 0 <= dc && dc < matrix[0].Length)
                yield return (dr, dc);
    }
    static Dictionary<Point, int> Part1(byte[][] matrix)
    {
        Dictionary<Point, int> map = [];
        for (int i = 0; i < matrix.Length; i++)
            for (int j = 0; j < matrix[0].Length; j++)
                if (Kernel3(matrix, i, j).All(x => matrix[x.Item1][x.Item2] > matrix[i][j]))
                    map[new Point(i, j)] = 1 + matrix[i][j];
        return map;
    }
    static int Part2(byte[][] matrix) =>
        Part1(matrix).Keys
            .Select(k =>
                {
                    Queue<Point> queue = new([k]);
                    HashSet<Point> visited = [];
                    while (queue.TryDequeue(out var p))
                        foreach (var np in Kernel3(matrix, p.Row, p.Col).Select(x => new Point(x.Item1, x.Item2)))
                            if (matrix[np.Row][np.Col] != 9 && visited.Add(np)) queue.Enqueue(np);
                    return visited.Count;
                })
            .OrderBy(x => x)
            .TakeLast(3)
            .Aggregate(1, (acc, x) => acc * x);
}