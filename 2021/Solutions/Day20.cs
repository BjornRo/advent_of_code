namespace aoc.Solutions;

public class Day20
{
    public static void Solve()
    {
        var data = File.ReadAllText("in/d20t.txt").Trim().Replace("\r\n", "\n").Split("\n\n");

        Console.WriteLine($"Part 1: {Part1()}");
        Console.WriteLine($"Part 2: {Part2()}");
    }

    static ulong Part1()
    {
        return 1;
    }
    static ulong Part2()
    {
        return 1;
    }
}
