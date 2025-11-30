namespace aoc.Solutions;

public class Day17
{
    public static void Solve()
    {
        HashSet<(int, int, int)> cube = InitCube(File.ReadAllLines("in/d17.txt"));

        Console.WriteLine($"Part 1: {Part1([.. cube], 6)}");
        Console.WriteLine($"Part 2: {Part2(InitHypercube(cube), 6)}");
    }

    static HashSet<(int, int, int)> InitCube(string[] matrix)
    {
        HashSet<(int, int, int)> cube = [];
        for (int i = 0; i < matrix.Length; i++)
            for (int j = 0; j < matrix[0].Length; j++)
                if (matrix[i][j] == '#') cube.Add((i, j, 0));
        return cube;
    }

    static HashSet<(int, int, int, int)> InitHypercube(HashSet<(int, int, int)> cube)
    {
        HashSet<(int, int, int, int)> hypercube = [];
        foreach (var (i, j, k) in cube) hypercube.Add((i, j, k, 0));
        return hypercube;
    }

    static int Part1(HashSet<(int, int, int)> cube, int cycles)
    {
        static IEnumerable<(int, int, int)> GetNeighbors((int, int, int) t)
        {
            var (i, j, k) = t;
            for (int di = -1; di <= 1; di++)
                for (int dj = -1; dj <= 1; dj++)
                    for (int dk = -1; dk <= 1; dk++)
                        if (di != 0 || dj != 0 || dk != 0)
                            yield return (i + di, j + dj, k + dk);
        }

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

    static int Part2(HashSet<(int, int, int, int)> hypercube, int cycles)
    {
        static IEnumerable<(int, int, int, int)> GetNeighbors((int, int, int, int) t)
        {
            var (i, j, k, w) = t;
            for (int di = -1; di <= 1; di++)
                for (int dj = -1; dj <= 1; dj++)
                    for (int dk = -1; dk <= 1; dk++)
                        for (int dw = -1; dw <= 1; dw++)
                            if (di != 0 || dj != 0 || dk != 0 || dw != 0)
                                yield return (i + di, j + dj, k + dk, w + dw);
        }

        HashSet<(int, int, int, int)> tmp_hypercube = [];

        for (int cycle = 0; cycle < cycles; cycle++)
        {
            tmp_hypercube.Clear();
            int mini, maxi, minj, maxj, mink, maxk, minw, maxw;
            mini = minj = mink = minw = int.MaxValue;
            maxi = maxj = maxk = maxw = int.MinValue;

            foreach (var (i, j, k, w) in hypercube)
            {
                if (i < mini) mini = i;
                if (j < minj) minj = j;
                if (k < mink) mink = k;
                if (w < minw) minw = w;
                if (i > maxi) maxi = i;
                if (j > maxj) maxj = j;
                if (k > maxk) maxk = k;
                if (w > maxw) maxw = w;
            }
            for (int i = mini - 1; i <= maxi + 1; i++)
                for (int j = minj - 1; j <= maxj + 1; j++)
                    for (int k = mink - 1; k <= maxk + 1; k++)
                        for (int w = minw - 1; w <= maxw + 1; w++)
                        {
                            var neighbors = 0;
                            var pos = (i, j, k, w);
                            foreach (var neighbor in GetNeighbors(pos))
                                if (hypercube.Contains(neighbor))
                                    neighbors += 1;
                            var active = hypercube.Contains(pos);
                            if (active)
                            {
                                if (neighbors == 2 || neighbors == 3) tmp_hypercube.Add(pos);
                            }
                            else
                                if (neighbors == 3) tmp_hypercube.Add(pos);
                        }
            (tmp_hypercube, hypercube) = (hypercube, tmp_hypercube);
        }
        return hypercube.Count;
    }
}
