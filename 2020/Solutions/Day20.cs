namespace aoc.Solutions;


public partial class Day20
{
    const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
    static void Print(object? s)
    {
        Console.WriteLine(s);
    }
    static void Print()
    {
        Console.WriteLine();
    }
    public static void Solve()
    {
        string[] data = File.ReadAllText("in/d20t.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);
        var (corners, allTiles) = Part1(Parse(data));

        Console.WriteLine($"Part 1: {corners.Aggregate(1UL, (acc, corner) => acc * (ulong)corner.ID)}");
        Part2(corners, allTiles);
        Console.WriteLine($"Part 2: {2}");
    }

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

    static void Part2(Tile[] corners, Tile[] allTiles)
    {
        var DIM = (int)Math.Sqrt(allTiles.Length);
        Tile[,] matrix = new Tile[DIM, DIM];
        foreach (var c in corners)
        {
            Print(c.ID);
            foreach (var k in c.Neighbors)
            {
                Print(k);
            }
            Print();
        }

        // tiles[0].Flip();
        // Print(tiles[0].ID);
        // foreach (var t in tiles[0].SidesNESW)
        // {
        //     Console.Write($"{t} ");
        // }
        // Print();
        // foreach (var t in tiles[^1].SidesNESW)
        // {
        //     Console.Write($"{t} ");
        // }
        // Print();
    }

    static (Tile[] corners, Tile[] allTiles) Part1(in Dictionary<int, char[][]> inTiles)
    {
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
                            tiles[i].Neighbors.Add(tiles[j].ID);
                            tiles[i].Neighbors.Add(tiles[k].ID);
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

    class Tile
    {
        public int ID { get; set; }
        public uint[] SidesNESW { get; set; } = new uint[4];
        public uint[] FlippedSidesNESW { get; set; } = new uint[4];
        public char[,] Grid { get; set; }
        public HashSet<int> Neighbors = [];
        readonly int Length;

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
            Length = values.Length;
            Grid = new char[Length, Length];
            for (int i = 0; i < Length; i++)
                for (int j = 0; j < Length; j++)
                    Grid[i, j] = values[i][j];

            SidesNESW[0] = CharArrToInt(values[0]);
            SidesNESW[1] = CharArrToInt([.. values.Select(e => e[^1])]);
            SidesNESW[2] = CharArrToInt(values[^1]);
            SidesNESW[3] = CharArrToInt([.. values.Select(e => e[0])]);
            FlippedSidesNESW = (uint[])SidesNESW.Clone();
            for (int i = 0; i < FlippedSidesNESW.Length; i++)
            {
                uint reversedValue = 0;
                for (int j = 0; j < Length; j++)
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
            int rows = Grid.GetLength(0);
            int cols = Grid.GetLength(1);
            char[,] newGrid = new char[cols, rows];
            for (int i = 0; i < rows; i++)
                for (int j = 0; j < cols; j++)
                    newGrid[j, i] = Grid[i, j];

            Grid = newGrid;
        }

        // public void RotateCW()
        // {
        //     uint temp = SidesNESW[^1];
        //     for (int i = SidesNESW.Length - 1; i > 0; i--) SidesNESW[i] = SidesNESW[i - 1];
        //     SidesNESW[0] = temp;
        // }

        public void Flip()
        {
            (FlippedSidesNESW, SidesNESW) = (SidesNESW, FlippedSidesNESW);
        }
    }

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
}
