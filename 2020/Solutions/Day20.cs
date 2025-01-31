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

        Console.WriteLine($"Part 1: {Part1(Parse(data))}");
        // Console.WriteLine($"Part 2: {2}");
    }

    static Tile? IsCorner(Tile a, Tile b, Tile c)
    {
        for (int m = 0; m < 2; m++)
        {
            a.Flip();
            int side1 = -1;
            int side2 = -1;
            for (int n = 0; n < 2; n++)
            {
                b.Flip();
                foreach (var v in b.SidesNESW)
                {
                    side1 = Array.IndexOf(a.SidesNESW, v);
                    if (side1 != -1) break;
                }
                if (side1 != -1) break;
            }
            for (int n = 0; n < 2; n++)
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
            // Print(side1);
            // Print(side2);
            // Print(a.ID);
            if (diff == 1 || diff == 3)
            {
                return a;
            }
        }
        return null;
    }

    static int Part1(in Dictionary<int, char[][]> inTiles)
    {
        var DIM = (int)Math.Sqrt(inTiles.Count);
        Tile[,] matrix = new Tile[DIM, DIM];
        Tile[] tiles = [.. inTiles.Select(e => new Tile(e.Key, e.Value))];

        List<Tile> corners = [];

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

        for (int i = 0; i < tiles.Length; i++)
        {
            var found = false;
            for (int j = 0; j < tiles.Length; j++)
            {
                if (i == j) continue;
                for (int k = 0; k < tiles.Length; k++)
                {
                    if (i == k || j == k) continue;
                    if (IsCorner(tiles[i], tiles[j], tiles[k]) is Tile t)
                    {
                        Print(t.ID);
                        found = true;
                    }
                    if (found) break;
                }
                if (found) break;
            }
        }

        foreach (var c in corners)
        {
            Print(c.ID);
        }

        Print(corners.Count);
        return 1;
    }


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

    class Tile
    {
        public int ID { get; set; }
        public uint[] SidesNESW { get; set; } = new uint[4];
        readonly int Length;

        public Tile(int id, char[][] values)
        {
            ID = id;
            Length = values.Length;
            SidesNESW[0] = CharArrToInt(values[0]);
            SidesNESW[1] = CharArrToInt([.. values.Select(e => e[^1])]);
            SidesNESW[2] = CharArrToInt(values[^1]);
            SidesNESW[3] = CharArrToInt([.. values.Select(e => e[0])]);
        }
        public void RotateCW()
        {
            uint temp = SidesNESW[^1];
            for (int i = SidesNESW.Length - 1; i > 0; i--) SidesNESW[i] = SidesNESW[i - 1];
            SidesNESW[0] = temp;
        }
        public void RotateCCW()
        {
            uint temp = SidesNESW[0];
            for (int i = 0; i < SidesNESW.Length - 1; i++) SidesNESW[i] = SidesNESW[i + 1];
            SidesNESW[^1] = temp;
        }
        public void Flip()
        {
            for (int i = 0; i < SidesNESW.Length; i++)
            {
                uint reversedValue = 0;
                for (int j = 0; j < Length; j++)
                {
                    reversedValue <<= 1;
                    reversedValue |= SidesNESW[i] & 1;
                    SidesNESW[i] >>= 1;
                }
                SidesNESW[i] = reversedValue;
            }

        }
        public uint North()
        {
            return SidesNESW[0];
        }
        public uint East()
        {
            return SidesNESW[1];
        }
        public uint South()
        {
            return SidesNESW[2];
        }
        public uint West()
        {
            return SidesNESW[3];
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
