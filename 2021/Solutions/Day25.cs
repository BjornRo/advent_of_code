namespace aoc.Solutions;

public class Day25
{
    public static void Solve() =>
        Console.WriteLine($"Part 1: {Part1([.. File.ReadAllLines("in/d25.txt").Select(x => x.ToCharArray())])}");

    static int Part1(char[][] grid)
    {
        var (rows, cols) = (grid.Length, grid[0].Length);
        for (int k = 1; ; k += 1)
        {
            var tmpGrid = Utils.DeepCopy(grid);
            bool moved = false;
            foreach (var (i, j) in Utils.Cartesian(rows, cols))
                if (grid[i][j] == '>')
                {
                    var dj = (j + 1) % cols;
                    if (grid[i][dj] == '.')
                    {
                        (tmpGrid[i][dj], tmpGrid[i][j]) = ('>', '.');
                        moved = true;
                    }
                }
            grid = Utils.DeepCopy(tmpGrid);
            foreach (var (i, j) in Utils.Cartesian(rows, cols))
                if (grid[i][j] == 'v')
                {
                    var di = (i + 1) % rows;
                    if (grid[di][j] == '.')
                    {
                        (tmpGrid[di][j], tmpGrid[i][j]) = ('v', '.');
                        moved = true;
                    }
                }
            if (!moved) return k;
            grid = tmpGrid;
        }
    }
}