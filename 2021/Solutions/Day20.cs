namespace aoc.Solutions;

public class Day20
{
    public static void Solve()
    {
        var data = File.ReadAllText("in/d20.txt").Trim().Replace("\r\n", "\n").Split("\n\n");

        var enhance = data[0];
        var image = data[1].Split("\n");

        Console.WriteLine($"Part 1: {Enhancer(enhance, image, 2)}");
        Console.WriteLine($"Part 2: {Enhancer(enhance, image, 50)}");
    }
    static int Arr2Int(IEnumerable<byte> arr) => arr.Aggregate(0, (agg, v) => (agg << 1) | (v & 1));
    public static IEnumerable<(int, int)> Kernel3(int row, int col)
    {
        for (int i = -1; i < 2; i++)
            for (int j = -1; j < 2; j++)
                yield return (row + i, col + j);
    }
    static int Enhancer(string enhance, string[] image, int enhances)
    {
        HashSet<(int, int)> img = [];
        for (int row = 0; row < image.Length; row++)
            for (int col = 0; col < image[0].Length; col++)
                if (image[row][col] == '#') img.Add((row, col));

        HashSet<(int, int)> tmpImg = [];
        bool pixel = false;
        foreach (var _ in Enumerable.Range(0, enhances))
        {
            var ((minR, maxR), (minC, maxC)) = Utils.MinMax(img.ToArray());
            byte Test((int r, int c) a) =>
                (byte)(img.Contains(a) || (pixel && (a.r < minR || a.r > maxR || a.c < minC || a.c > maxC)) ? 1 : 0);
            for (int row = minR - 1; row <= maxR + 1; row++)
                for (int col = minC - 1; col <= maxC + 1; col++)
                    if (enhance[Arr2Int(Kernel3(row, col).Select(Test))] == '#') tmpImg.Add((row, col));
            (img, tmpImg) = (tmpImg, img);
            tmpImg.Clear();
            if (enhance[0] == '#' && enhance[^1] == '.') pixel = !pixel;
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
}
