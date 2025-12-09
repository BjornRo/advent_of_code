namespace aoc.Solutions;

public class Day09
{
    record Point(long Row, long Col)
    {
        public long DeltaR(Point o) => long.Abs(o.Row - Row) + 1;
        public long DeltaC(Point o) => long.Abs(o.Col - Col) + 1;
    }
    public static void Solve()
    {
        Point[] list = [.. File.ReadAllLines("in/d09t.txt")
            .Select(x =>
                {
                    var res = x.Split(",").Select(long.Parse).ToArray();
                    return new Point(res[0], res[1]);
                }
        )];

        // Console.WriteLine($"Part 1: {Part1(list)}");
        Console.WriteLine($"Part 2: {Part2(list)}");
    }

    static bool WithinBounds(Point[] list, Point p)
    {
        // https://en.wikipedia.org/wiki/Even%E2%80%93odd_rule
        var (x, y) = p;

        bool c = false;
        int N = list.Length;
        for (int i = 0; i < N; i += 1)
        {
            var (ax, ay) = list[i];
            var (bx, by) = list[(i + 1) % N];
            if (x == ax && y == ay) return true;
            if (ay > y != by > y)
            {
                var slope = (x - ax) * (by - ay) - (bx - ax) * (y - ay);
                if (slope == 0) return true;
                if (slope < 0 != by < ay) c = !c;
            }
        }
        return c;
    }

    static bool RectInBounds(Point[] list, Point[] rect)
    {
        if (!rect.All(p => WithinBounds(list, p))) return false;

        return true;
    }


    // too high 4582310446
    //          4562599890
    // too low  24679722
    static long? Part2(Point[] list)
    {
        // var map = list.ToHashSet();

        var items = list
            .SelectMany((a, i) => list
                .Skip(i + 1)
                .Select(b =>
                    {
                        Point[] corners = [a, b, new Point(b.Row, a.Col), new Point(a.Row, b.Col)];
                        return RectInBounds(list, corners) ? (long?)a.DeltaR(b) * a.DeltaC(b) : null;
                    })
                .Where(x => x != null)
                )
            .OrderBy(x => -x)
            .ToArray();


        foreach (var result in items.Take(30))
        {
            Console.WriteLine(result);
        }

        Console.WriteLine(items.Length);


        return items[0];
    }

    static long Part1(Point[] list) => list
            .SelectMany((a, i) => list
                .Skip(i + 1)
                .Select(b => a.DeltaR(b) * a.DeltaC(b)))
            .Max();
}
