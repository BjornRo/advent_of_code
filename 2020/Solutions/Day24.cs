namespace aoc.Solutions;

public partial class Day24
{
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
        int[] data = [.. File.ReadAllText("in/d24.txt").TrimEnd().ToCharArray().Select(e => e - '0')];

        Console.WriteLine($"Part 1: {Part1([.. data])}");
        // Console.WriteLine($"Part 2: {Part2([.. data])}");
    }

    static string Part1(in int[] data)
    {

        return "baba";
    }
}
