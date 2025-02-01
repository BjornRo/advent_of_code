using System.Numerics;

namespace aoc.Solutions;

public partial class Day25
{
    static void Print(object? s)
    {
        Console.WriteLine(s);
    }
    static void Print()
    {
        Console.WriteLine();
    }


    enum Direction
    {
        East,
        SouthEast,
        SouthWest,
        West,
        NorthWest,
        NorthEast,
    }

    static Direction[][] Parse(string[] data)
    {
        List<Direction[]> output = [];
        foreach (var line in data)
        {
            List<Direction> steps = [];
            int i = 0;
            while (i < line.Length)
            {
                if (i < line.Length - 1)
                {
                    Direction? result = line[i..(i + 2)] switch
                    {
                        "se" => Direction.SouthEast,
                        "sw" => Direction.SouthWest,
                        "nw" => Direction.NorthWest,
                        "ne" => Direction.NorthEast,
                        _ => null,
                    };
                    if (result is Direction dir)
                    {
                        steps.Add(dir);
                        i += 2;
                        continue;
                    }
                }
                if (line[i] == 'e') steps.Add(Direction.East);
                else steps.Add(Direction.West);
                i += 1;
            }
            output.Add([.. steps]);
        }
        return [.. output];
    }

    public static void Solve()
    {
        Direction[][] data = Parse(File.ReadAllLines("in/d24.txt"));

        var tiles = Tiler([.. data]);
        Console.WriteLine($"Part 1: {tiles.Count}");
        Console.WriteLine($"Part 2: {Segregation(tiles)}");
    }

    static HashSet<(int, int)> Tiler(Direction[][] data)
    {
        static (int, int) C2I(Complex c) { return ((int)c.Real, (int)c.Imaginary); }
        Dictionary<(int, int), int> tiles = [];
        foreach (var steps in data)
        {
            var pos = new Complex(0, 0);
            foreach (var step in steps)
            {
                pos += step switch
                {
                    Direction.East => new Complex(0, 2),
                    Direction.West => new Complex(0, -2),
                    Direction.SouthEast => new Complex(1, 1),
                    Direction.SouthWest => new Complex(1, -1),
                    Direction.NorthEast => new Complex(-1, 1),
                    Direction.NorthWest => new Complex(-1, -1),
                    _ => throw new NotImplementedException(),
                };
            }
            if (tiles.TryGetValue(C2I(pos), out int value)) tiles[C2I(pos)] = value + 1;
            else tiles[C2I(pos)] = 1;
        }
        return [.. tiles.Where(e => e.Value % 2 == 1).Select(e => e.Key)];
    }

    static int Segregation(HashSet<(int, int)> blackTiles)
    {
        static IEnumerable<(int, int)> GetNeighbors((int, int) pos)
        {
            var (i, j) = pos;
            (int, int)[] neighbors = [(0, 2), (0, -2), (1, 1), (1, -1), (-1, 1), (-1, -1)];
            foreach (var (di, dj) in neighbors) yield return (i + di, j + dj);
        }
        HashSet<(int, int)> tmpTiles = [];
        for (int _ = 0; _ < 100; _++)
        {
            tmpTiles.Clear();
            int mini, maxi, minj, maxj;
            mini = minj = int.MaxValue;
            maxi = maxj = int.MinValue;

            foreach (var (i, j) in blackTiles)
            {
                if (i < mini) mini = i;
                if (j < minj) minj = j;
                if (i > maxi) maxi = i;
                if (j > maxj) maxj = j;
            }
            for (int i = mini - 1; i <= maxi + 1; i++)
                for (int j = minj - 1; j <= maxj + 1; j++)
                {
                    var neighbors = 0;
                    var pos = (i, j);
                    foreach (var neighbor in GetNeighbors(pos))
                        if (blackTiles.Contains(neighbor)) neighbors += 1;

                    if (blackTiles.Contains(pos))
                    {
                        if (neighbors == 1 || neighbors == 2) tmpTiles.Add(pos);
                    }
                    else if (neighbors == 2) tmpTiles.Add(pos);

                }
            (tmpTiles, blackTiles) = (blackTiles, tmpTiles);
        }
        return blackTiles.Count;
    }
}
