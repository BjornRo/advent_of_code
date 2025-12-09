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

        Console.WriteLine($"Part 1: {Part1(list)}");
        Console.WriteLine($"Part 2: {Part2(list)}");

        sw.Stop();
        Console.WriteLine(sw.Elapsed.TotalSeconds);
    }
    static long Part1(Point[] list) => list
            .SelectMany((a, i) => list
                .Skip(i + 1)
                .Select(b => a.DeltaR(b) * a.DeltaC(b)))
            .Max();
    static readonly ConcurrentDictionary<Point, bool> memo = [];
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
        memo.TryAdd(p, c);
        return c;
    }
    static bool RectInBounds(Point[] list, Point a, Point b, HashSet<Point> edge)
    {
        int minRow = int.Min(a.Row, b.Row);
        int maxRow = int.Max(a.Row, b.Row);
        int minCol = int.Min(a.Col, b.Col);
        int maxCol = int.Max(a.Col, b.Col);

        for (int i = minRow; i <= maxRow; i++)
            if (!WithinBounds(list, edge, new Point(i, minCol)) ||
                !WithinBounds(list, edge, new Point(i, maxCol))) return false;

        for (int i = minCol; i <= maxCol; i++)
            if (!WithinBounds(list, edge, new Point(minRow, i)) ||
                !WithinBounds(list, edge, new Point(maxRow, i))) return false;

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

        return list
            .SelectMany((a, i) => list
                .Skip(i + 1)
                .AsParallel()
                .Select(b => RectInBounds(list, a, b, edges) ? a.DeltaR(b) * a.DeltaC(b) : 0)
            )
            .Max();
    }
}
