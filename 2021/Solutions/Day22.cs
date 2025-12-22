using System.Numerics;

namespace aoc.Solutions;

public class Day22
{
    record Range(int Start, int End)
    {
        public BigInteger Length = End - Start + 1;
        public Range? Intersect(Range o)
        {
            var start = Math.Max(Start, o.Start);
            var end = Math.Min(End, o.End);
            return start <= end ? new(start, end) : null;
        }
        public bool InBounds(Range r) => r.Start <= Start && End <= r.End;
    }

    record Cube(BigInteger St, Range X, Range Y, Range Z)
    {
        public BigInteger St { get; set; } = St;
        public Cube FlipSign() { St *= -1; return this; }
        public BigInteger Volume = X.Length * Y.Length * Z.Length;
        public Cube? Intersect(Cube o) =>
            X.Intersect(o.X) is Range x &&
            Y.Intersect(o.Y) is Range y &&
            Z.Intersect(o.Z) is Range z ? new(St, x, y, z) : null;
    }
    static Cube Parse(string s)
    {
        var res = s.Split(" ", 2);
        var ranges = res[^1]
            .Split(",")
            .Select(e => e.Split("=")[^1].Split("..").Select(int.Parse).ToArray())
            .Select(xs => new Range(xs[0], xs[1]))
            .ToArray();

        return new(res[0] == "on" ? 1 : -1, ranges[0], ranges[1], ranges[2]);
    }
    public static void Solve()
    {
        var data = File.ReadAllLines("in/d22.txt").Select(Parse).ToArray();

        var bound = new Range(-50, 50);
        Console.WriteLine($"Part 1: {Solve(data.Where(c => c.X.InBounds(bound) && c.Y.InBounds(bound) && c.Z.InBounds(bound)))}");
        Console.WriteLine($"Part 2: {Solve(data)}");
    }
    static BigInteger Solve(IEnumerable<Cube> data) =>
        data.Aggregate(Array.Empty<Cube>(), (acc, c) =>
            [.. acc, .. acc.Select(b => b.Intersect(c)?.FlipSign()).OfType<Cube>().Concat(c.St == 1 ? [c] : [])]
        ).Aggregate(BigInteger.Zero, (acc, c) => acc + c.St * c.Volume);
}