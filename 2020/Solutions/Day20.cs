namespace aoc.Solutions;

public partial class Day20
{
    const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;

    static Dictionary<int, char[][]> Parse(string[] data)
    {
        Dictionary<int, char[][]> tiles = [];
        foreach (var sub in data)
        {
            var subSplit = sub.Split(["\r\n", "\n"], count: 2, SPLITOPT);
            var tileID = int.Parse(new string([.. subSplit[0].ToCharArray().Where(char.IsDigit)]));
            tiles[tileID] = [.. subSplit[1].Split(["\r\n", "\n"], SPLITOPT).Select(e => e.ToCharArray())];
        }
        return tiles;
    }

    public static void Solve()
    {
        string[] data = File.ReadAllText("in/d20.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);
        var (corners, allTiles) = Part1(Parse(data));

        Console.WriteLine($"Part 1: {corners.Aggregate(1UL, (acc, corner) => acc * (ulong)corner.ID)}");
        Console.WriteLine($"Part 2: {Part2(corners, allTiles)}");
    }

    class Tile
    {
        public int ID { get; set; }
        public uint[] SidesNESW { get; set; } = new uint[4];
        public uint[] FlippedSidesNESW { get; set; } = new uint[4];
        public char[][] Grid { get; set; }
        public List<Tile> Neighbors = [];

        public Tile(int id, char[][] values)
        {
            static uint CharArrToInt(char[] arr)
            {
                uint value = 0;
                foreach (char c in arr)
                {
                    value <<= 1;
                    if (c == '#') value |= 1;
                }
                return value;
            }

            ID = id;
            Grid = values;

            SidesNESW[0] = CharArrToInt(values[0]);
            SidesNESW[1] = CharArrToInt([.. values.Select(e => e[^1])]);
            SidesNESW[2] = CharArrToInt(values[^1]);
            SidesNESW[3] = CharArrToInt([.. values.Select(e => e[0])]);
            FlippedSidesNESW = (uint[])SidesNESW.Clone();
            for (int i = 0; i < FlippedSidesNESW.Length; i++)
            {
                uint reversedValue = 0;
                for (int j = 0; j < Grid.Length; j++)
                {
                    reversedValue <<= 1;
                    reversedValue |= FlippedSidesNESW[i] & 1;
                    FlippedSidesNESW[i] >>= 1;
                }
                FlippedSidesNESW[i] = reversedValue;
            }
        }
        public void RotateGridCW()
        {
            FlipGrid();
            TransposeGrid();
        }
        public void FlipGrid()
        {
            Array.Reverse(Grid);
            Flip();
        }
        public void TransposeGrid()
        {
            int rows = Grid.Length;
            int cols = Grid[0].Length;

            char[][] transposed = new char[cols][];
            for (int i = 0; i < cols; i++)
            {
                transposed[i] = new char[rows];
                for (int j = 0; j < rows; j++)
                    transposed[i][j] = Grid[j][i];
            }
            Grid = transposed;
        }
        public char[] North()
        {
            return Grid[0];
        }
        public char[] South()
        {
            return Grid[^1];
        }
        public char[] East()
        {
            return [.. Grid.Select(e => e[^1])];
        }
        public char[] West()
        {
            return [.. Grid.Select(e => e[0])];
        }
        public void Flip()
        {
            (FlippedSidesNESW, SidesNESW) = (SidesNESW, FlippedSidesNESW);
        }
    }

    static bool Matches(char[] a, char[] b)
    {
        return a.Zip(b).All(e => e.First == e.Second);
    }

    static Tile? IsCorner(Tile a, Tile b, Tile c)
    {
        for (int i = 0; i < 2; i++)
        {
            a.Flip();
            int side1 = -1;
            int side2 = -1;
            for (int j = 0; j < 2; j++)
            {
                b.Flip();
                foreach (var v in b.SidesNESW)
                {
                    side1 = Array.IndexOf(a.SidesNESW, v);
                    if (side1 != -1) break;
                }
                if (side1 != -1) break;
            }
            for (int j = 0; j < 2; j++)
            {
                c.Flip();
                foreach (var v in c.SidesNESW)
                {
                    side2 = Array.IndexOf(a.SidesNESW, v);
                    if (side2 != -1) break;
                }
                if (side2 != -1) break;
            }
            var diff = int.Abs(int.Abs(side1) - int.Abs(side2));
            if (diff == 1 || diff == 3) return a;
        }
        return null;
    }

    static (Tile[] corners, Tile[] allTiles) Part1(in Dictionary<int, char[][]> inTiles)
    {
        static bool CornerTieBreaker(Tile a, Tile b)
        {
            for (int i = 0; i < 2; i++)
            {
                b.Flip();
                foreach (var v in b.SidesNESW)
                    if (Array.IndexOf(a.SidesNESW, v) != -1) return false;
            }
            return true;
        }

        Tile[] tiles = [.. inTiles.Select(e => new Tile(e.Key, e.Value))];
        List<Tile> corners = [];

        for (int i = 0; i < tiles.Length; i++)
        {
            if (corners.Count == 4) break;
            var found = false;
            for (int j = 0; j < tiles.Length; j++)
            {
                if (i == j) continue;
                if (corners.Count == 4) break;
                for (int k = 0; k < tiles.Length; k++)
                {
                    if (i == k || j == k) continue;
                    if (corners.Count == 4) break;
                    if (IsCorner(tiles[i], tiles[j], tiles[k]) is Tile t)
                    {
                        var isCorner = true;
                        for (int l = 0; l < tiles.Length; l++)
                            if (l != i && l != j && l != k)
                                if (!CornerTieBreaker(t, tiles[l]))
                                {
                                    isCorner = false;
                                    break;
                                }
                        if (isCorner)
                        {
                            tiles[i].Neighbors.Add(tiles[j]);
                            tiles[i].Neighbors.Add(tiles[k]);
                            found = true;
                            corners.Add(t);
                        }
                    }
                    if (found) break;
                }
                if (found) break;
            }
        }
        return ([.. corners], tiles);
    }

    static void OrientateCorner(Tile corner)
    {
        Tile a = corner.Neighbors[0];
        Tile b = corner.Neighbors[1];
        for (int i = 0; i < 2; i++)
        {
            corner.FlipGrid();
            for (int j = 0; j < 4; j++)
            {
                corner.RotateGridCW();
                var aMatch = false;
                for (int k = 0; k < 2; k++)
                {
                    a.FlipGrid();
                    for (int l = 0; l < 4; l++)
                    {
                        a.RotateGridCW();
                        if (Matches(corner.East(), a.West()))
                        {
                            aMatch = true;
                            break;
                        }
                    }
                    if (aMatch) break;
                }
                if (!aMatch) continue;
                for (int k = 0; k < 2; k++)
                {
                    b.FlipGrid();
                    for (int l = 0; l < 4; l++)
                    {
                        b.RotateGridCW();
                        if (Matches(corner.South(), b.North())) return;
                    }
                }
            }
        }
    }

    static int Part2(in Tile[] corners, in Tile[] allTiles)
    {
        OrientateCorner(corners[0]);
        Dictionary<(int, int), Tile> map = [];
        map[(0, 0)] = corners[0];
        map[(0, 1)] = corners[0].Neighbors[0];
        map[(1, 0)] = corners[0].Neighbors[1];

        int row = 0;
        int col = 0;
        Queue<Tile> queue = [];
        foreach (var t in allTiles)
        {
            if (t.ID == corners[0].ID || t.ID == corners[0].Neighbors[0].ID || t.ID == corners[0].Neighbors[1].ID)
                continue;
            queue.Enqueue(t);
        }
        var DIM = (int)Math.Sqrt(allTiles.Length);
        while (queue.TryDequeue(out var result))
        {
            while (map.ContainsKey((row, col)))
            {
                col += 1;
                if (col >= DIM)
                {
                    col = 0;
                    row += 1;
                }
            }
            var foundSlot = false;
            for (int i = 0; i < 2; i++)
            {
                result.FlipGrid();
                for (int l = 0; l < 4; l++)
                {
                    result.RotateGridCW();
                    if (col == 0)
                    {
                        if (Matches(map[(row - 1, col)].South(), result.North()))
                        {
                            map[(row, col)] = result;
                            foundSlot = true;
                            break;
                        }
                    }
                    else if (Matches(map[(row, col - 1)].East(), result.West()))
                    {
                        map[(row, col)] = result;
                        foundSlot = true;
                        break;
                    }
                }
                if (foundSlot) break;
            }
            if (!foundSlot) queue.Enqueue(result);
        }

        string[] seaMonster = [
            "                  # ",
            "#    ##    ##    ###",
            " #  #  #  #  #  #   "
            ];

        List<(int, int)> seaMonsterDot = [];
        for (int i = 0; i < seaMonster.Length; i++)
            for (int j = 0; j < seaMonster[0].Length; j++)
                if (seaMonster[i][j] == '#') seaMonsterDot.Add((i, j));

        bool MatchesSeaMonster(Tile grid, int startRow, int startCol, bool delete)
        {
            foreach (var (dr, dc) in seaMonsterDot)
            {
                int row = startRow + dr;
                int col = startCol + dc;
                if (row >= grid.Grid.Length || col >= grid.Grid[0].Length || grid.Grid[row][col] != '#')
                    return false;
                if (delete) grid.Grid[row][col] = 'O';
            }
            return true;
        }

        var subGridDim = corners[0].Grid.Length - 2;
        var matrixDim = subGridDim * DIM;
        char[][] matrix = new char[matrixDim][];
        for (int i = 0; i < matrixDim; i++) matrix[i] = new char[matrixDim];
        foreach (var kvp in map)
        {
            int startRow = kvp.Key.Item1 * subGridDim;
            int startCol = kvp.Key.Item2 * subGridDim;

            for (int i = 0; i < subGridDim; i++)
                for (int j = 0; j < subGridDim; j++)
                    matrix[startRow + i][startCol + j] = kvp.Value.Grid[i + 1][j + 1];
        }

        Tile grid = new(0, matrix);
        for (int i = 0; i < 2; i++)
        {
            var found = false;
            grid.TransposeGrid();
            for (int j = 0; j < 4; j++)
            {
                grid.RotateGridCW();
                for (int k = 0; k < grid.Grid.Length - seaMonster.Length + 1; k++)
                    for (int l = 0; l < grid.Grid[0].Length - seaMonster[0].Length + 1; l++)
                        if (MatchesSeaMonster(grid, k, l, false))
                        {
                            MatchesSeaMonster(grid, k, l, true);
                            found = true;
                        }
                if (found) break;
            }
            if (found) break;
        }
        return grid.Grid.SelectMany(row => row).Count(c => c == '#');
    }
}
