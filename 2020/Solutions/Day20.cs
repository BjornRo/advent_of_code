namespace aoc.Solutions;

public partial class Day20
{
    public static void Solve()
    {
        const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
        string[] data = File.ReadAllText("in/d19.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);

        Console.WriteLine($"Part 1: {1}");
        Console.WriteLine($"Part 2: {2}");
    }


}
