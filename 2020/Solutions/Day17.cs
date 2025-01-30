namespace aoc.Solutions;

public class Day17
{
    public static void Solve()
    {
        HashSet<(int, int, int)> cube = InitCube(File.ReadAllLines("in/d17.txt"));

        Console.WriteLine($"Part 1: {Part1([.. cube], 6)}");
        // Console.WriteLine($"Part 2: {Part2([.. matrix.Select(row => row.ToCharArray())])}");
    }

    static HashSet<(int, int, int)> InitCube(string[] matrix)
    {
        HashSet<(int, int, int)> cube = [];
        for (int i = 0; i < matrix.Length; i++)
            for (int j = 0; j < matrix[0].Length; j++)
                if (matrix[i][j] == '#') cube.Add((i, j, 0));
        return cube;
    }


    static IEnumerable<(int, int, int)> GetNeighbors((int, int, int) t)
    {
        var (i, j, k) = t;
        for (int di = -1; di <= 1; di++)
            for (int dj = -1; dj <= 1; dj++)
                for (int dk = -1; dk <= 1; dk++)
                    if (di != 0 || dj != 0 || dk != 0)
                        yield return (i + di, j + dj, k + dk);
    }

    static int Part1(HashSet<(int, int, int)> cube, int cycles)
    {
        HashSet<(int, int, int)> tmp_cube = [];

        for (int cycle = 0; cycle < cycles; cycle++)
        {
            tmp_cube.Clear();
            int mini, maxi, minj, maxj, mink, maxk;
            mini = minj = mink = int.MaxValue;
            maxi = maxj = maxk = int.MinValue;

            foreach (var (i, j, k) in cube)
            {
                if (i < mini) mini = i;
                if (j < minj) minj = j;
                if (k < mink) mink = k;
                if (i > maxi) maxi = i;
                if (j > maxj) maxj = j;
                if (k > maxk) maxk = k;
            }
            for (int i = mini - 1; i <= maxi + 1; i++)
                for (int j = minj - 1; j <= maxj + 1; j++)
                    for (int k = mink - 1; k <= maxk + 1; k++)
                    {
                        var neighbors = 0;
                        var pos = (i, j, k);
                        foreach (var neighbor in GetNeighbors(pos))
                            if (cube.Contains(neighbor))
                                neighbors += 1;
                        var active = cube.Contains(pos);
                        if (active)
                        {
                            if (neighbors == 2 || neighbors == 3) tmp_cube.Add(pos);
                        }
                        else
                            if (neighbors == 3) tmp_cube.Add(pos);
                    }
            (tmp_cube, cube) = (cube, tmp_cube);
        }
        return cube.Count;
    }
}


// static List<(int, int)>[,] GetVisibleSeats(char[][] grid)
// {
//     int rows = grid.Length;
//     int cols = grid[0].Length;
//     var directions = new (int, int)[]
//         { (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1) };

//     var visibleSeats = new List<(int, int)>[rows, cols];
//     for (int r = 0; r < rows; r++)
//         for (int c = 0; c < cols; c++)
//         {
//             if (grid[r][c] == '.') continue;
//             visibleSeats[r, c] = [];

//             foreach (var (dr, dc) in directions)
//             {
//                 int nr = r + dr, nc = c + dc;
//                 while (0 <= nr && nr < rows && 0 <= nc && nc < cols)
//                 {
//                     if (grid[nr][nc] == 'L' || grid[nr][nc] == '#')
//                     {
//                         visibleSeats[r, c].Add((nr, nc));
//                         break;
//                     }
//                     nr += dr;
//                     nc += dc;
//                 }
//             }
//         }
//     return visibleSeats;
// }
