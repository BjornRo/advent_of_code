namespace aoc.Solutions;

public class Day20
{
    public static void Solve()
    {
        var data = File.ReadAllText("in/d20t.txt").Trim().Replace("\r\n", "\n").Split("\n\n");

        var enhance = data[0];
        var image = data[1].Split("\n");

        Console.WriteLine($"Part 1: {Part1(enhance, image)}");
        Console.WriteLine($"Part 2: {Part2()}");
    }
    static int Arr2Int(IEnumerable<byte> arr) => arr.Aggregate(0, (agg, v) => (agg << 1) | (v & 1));
    public static IEnumerable<(int, int)> Kernel3(int row, int col)
    {
        for (int i = -1; i < 2; i++)
            for (int j = -1; j < 2; j++)
                yield return (row + i, col + j);
    }
    // 5520 5357 too high
    static int Part1(string enhance, string[] image)
    {
        HashSet<(int, int)> img = [];
        for (int row = 0; row < image.Length; row++)
            for (int col = 0; col < image[0].Length; col++)
                if (image[row][col] == '#') img.Add((row, col));

        HashSet<(int, int)> tmpImg = [];
        foreach (var _ in Enumerable.Range(0, 2))
        {
            var ((minRow, maxRow), (minCol, maxCol)) = Utils.MinMax(img.ToArray());
            for (int row = minRow - 1; row <= maxRow + 1; row++)
                for (int col = minCol - 1; col <= maxCol + 1; col++)
                {
                    var bin = new byte[9];
                    foreach (var (i, pos) in Kernel3(row, col).Select((x, i) => (i, x)))
                    {
                        if (img.Contains(pos)) bin[i] = 1;
                    }
                    if (enhance[Arr2Int(bin)] == '#') tmpImg.Add((row, col));
                }
            (img, tmpImg) = (tmpImg, img);
            tmpImg.Clear();
            // PM(img);
        }
        return img.Count;
    }
    static void PM(HashSet<(int, int)> set)
    {
        var ((minRow, maxRow), (minCol, maxCol)) = Utils.MinMax(set.ToArray());
        int numRows = maxRow - minRow + 1, numCols = maxCol - minCol + 1;
        char[][] matrix = new char[numRows][];
        for (int r = 0; r < numRows; r++)
        {
            matrix[r] = new char[numCols];
            for (int c = 0; c < numCols; c++) matrix[r][c] = ' ';
        }
        foreach (var (row, col) in set)
            matrix[row - minRow][col - minCol] = '#';

        foreach (var row in matrix)
            Console.WriteLine(string.Join("", row));
        Console.WriteLine();
    }
    static ulong Part2()
    {
        return 1;
    }
}
