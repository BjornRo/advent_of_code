using System.Collections.Concurrent;

namespace aoc.Solutions;

using System;
using System.Diagnostics;
public class Day09
{
    record Point(int Row, int Col)
    {
        public long DeltaR(Point o) => long.Abs(o.Row - Row) + 1;
        public long DeltaC(Point o) => long.Abs(o.Col - Col) + 1;
    }
    public static void Solve()
    {
        Point[] list = [.. File.ReadAllLines("in/d09.txt")
            .Select(x =>
                {
                    var res = x.Split(",").Select(int.Parse).ToArray();
                    return new Point(res[1], res[0]);
                }
        )];

        var sw = Stopwatch.StartNew();

        Console.WriteLine($"Part 1: {Part1(list).MaxBy(x => x.Item1).Item1}");
        Console.WriteLine($"Part 2: {Part2(list)}");

        sw.Stop();
        Console.WriteLine(sw.Elapsed.TotalSeconds);
    }
    static IEnumerable<(long, Point a, Point b)> Part1(Point[] list) =>
        list.SelectMany((a, i) => list.Skip(i + 1).Select(b => (a.DeltaR(b) * a.DeltaC(b), a, b)));

    static readonly Dictionary<Point, bool> memo = [];
    static bool WithinBounds(Point[] list, HashSet<Point> edge, Point p)
    {
        // https://en.wikipedia.org/wiki/Even%E2%80%93odd_rule
        if (memo.TryGetValue(p, out var res)) return res;

        bool c = false;
        if (edge.Contains(p))
        {
            c = true;
        }
        else
        {
            var (x, y) = p;

            int N = list.Length;
            for (int i = 0; i < N; i += 1)
            {
                var (ax, ay) = list[i];
                var (bx, by) = list[(i + 1) % N];
                if (x == ax && y == ay)
                {
                    c = true;
                    break;
                }
                if (ay > y != by > y)
                {
                    var slope = (x - ax) * (by - ay) - (bx - ax) * (y - ay);
                    if (slope == 0)
                    {
                        c = true;
                        break;
                    }
                    if (slope < 0 != by < ay) c = !c;
                }
            }
        }
        memo.Add(p, c);
        return c;
    }
    static readonly Dictionary<Point, bool> memor = [];
    static readonly Dictionary<Point, bool> memoc = [];
    static bool RectInBounds(Point[] list, Point a, Point b, HashSet<Point> edge)
    {
        int minRow = int.Min(a.Row, b.Row);
        int maxRow = int.Max(a.Row, b.Row);
        int minCol = int.Min(a.Col, b.Col);
        int maxCol = int.Max(a.Col, b.Col);

        Point r = new(minRow, maxRow);
        Point c = new(minCol, maxCol);
        bool? rb = memor.TryGetValue(r, out var rr) ? rr : null;
        bool? cb = memoc.TryGetValue(c, out var cr) ? cr : null;
        if (rb == true && cb == true) return true;
        if (rb == false || cb == false) return false;

        if (rb == null)
            for (int i = minRow; i <= maxRow; i++)
                if (!WithinBounds(list, edge, new Point(i, minCol)) ||
                    !WithinBounds(list, edge, new Point(i, maxCol)))
                {
                    memor.Add(r, false);
                    return false;
                }

        if (cb == null)
            for (int i = minCol; i <= maxCol; i++)
                if (!WithinBounds(list, edge, new Point(minRow, i)) ||
                    !WithinBounds(list, edge, new Point(maxRow, i)))
                {
                    memoc.Add(c, false);
                    return false;
                }

        memor.Add(r, true);
        memoc.Add(c, true);
        return true;
    }
    static long Part2(Point[] list)
    {
        var edges = new HashSet<Point>();
        int N = list.Length;

        for (int i = 0; i < N; i++)
        {
            Point start = list[i];
            Point end = list[(i + 1) % N];

            int colMin = Math.Min(start.Col, end.Col);
            int colMax = Math.Max(start.Col, end.Col);
            for (int r = Math.Min(start.Row, end.Row); r <= Math.Max(start.Row, end.Row); r++)
                for (int c = colMin; c <= colMax; c++)
                    edges.Add(new Point(r, c));
        }

        foreach (var (res, a, b) in Part1(list).OrderBy(x => -x.Item1))
            if (RectInBounds(list, a, b, edges))
                return res;

        return 0;
    }
}
