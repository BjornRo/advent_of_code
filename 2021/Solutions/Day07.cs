namespace aoc.Solutions;

public class Day07
{
    public static void Solve()
    {
        var data = File.ReadAllText("in/d07.txt")
            .TrimEnd()
            .Split(",")
            .Select(long.Parse)
            .OrderBy(x => x)
            .ToArray();

        Console.WriteLine($"Part 1: {data.Sum(x => Math.Abs(x - Median(data)))}");
        Console.WriteLine($"Part 2: {data.Sum(x => Arithmetic(Math.Abs(x - (long)data.Average())))}");
    }
    static long Arithmetic(long N) => N * (N + 1) / 2;
    static long Median(long[] data) => (data[data.Length / 2] + data[data.Length / 2 - 1]) / 2;
}