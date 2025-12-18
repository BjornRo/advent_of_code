namespace aoc.Solutions;

public class Day07
{
    static long Arithmetic(long N) => N * (N + 1) / 2;
    public static void Solve()
    {
        var data = File.ReadAllText("in/d07.txt")
            .TrimEnd()
            .Split(",")
            .Select(long.Parse)
            .OrderBy(x => x)
            .ToArray();

        Console.WriteLine($"Part 1: {data.Sum(x => Math.Abs(x - Part1(data)))}");
        Console.WriteLine($"Part 2: {data.Sum(x => Arithmetic(Math.Abs(x - Part2(data))))}");
    }
    static long Part1(long[] data) => (data[data.Length / 2] + data[data.Length / 2 - 1]) / 2;
    static long Part2(long[] data) => data.Sum() / data.Length;
}