using System.Numerics;

namespace aoc.Solutions;

public class Day14
{
    public static void Solve()
    {
        string[] steps = File.ReadAllLines("in/d13.txt");

        var timestamp = long.Parse(steps[0]);
        var busIDs = steps[1].Split(",");

        Console.WriteLine($"Part 1: {Part1(timestamp, busIDs)}");
        Console.WriteLine($"Part 2: {Part2(busIDs)}");
    }

    static long Part1(long ts, in string[] busIDs)
    {
        var (waitTime, busID) = busIDs
            .Where(e => e != "x")
            .Select(long.Parse)
            .Select(e => ((ts + e - 1) / e * e - ts, e))
            .Min();
        return waitTime * busID;
    }

    static BigInteger CRT(long[] num, long[] rem)
    {
        BigInteger prod = num.Aggregate(BigInteger.One, (a, b) => a * b);
        BigInteger sum = 0;

        for (int i = 0; i < num.Length; i++)
        {
            BigInteger pp = prod / num[i];
            sum += rem[i] * ModularInverse(pp, num[i]) * pp;
        }
        return sum % prod;
    }

    static BigInteger ModularInverse(BigInteger a, BigInteger m)
    {
        BigInteger m0 = m, t, q;
        BigInteger x0 = 0, x1 = 1;
        if (m == 1) return 0;
        while (a > 1)
        {
            q = a / m;
            t = m;
            m = a % m;
            a = t;
            t = x0;
            x0 = x1 - q * x0;
            x1 = t;
        }

        return (x1 + m0) % m0;
    }

    static BigInteger Part2(in string[] busIDs)
    {
        var remainders = busIDs
            .Select((e, i) => (e, i))
            .Where(e => e.e != "x")
            .Select(e => (long.Parse(e.e), long.Parse(e.e) - e.i))
            .ToArray();
        return CRT([.. remainders.Select(p => p.Item1)], [.. remainders.Select(p => p.Item2)]);
    }
}
