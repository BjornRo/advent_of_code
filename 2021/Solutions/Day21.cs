namespace aoc.Solutions;

public class Day21
{
    public static void Solve()
    {
        var startPos = File.ReadAllLines("in/d21t.txt").Select(x => x[^1] - '0').ToArray();

        Console.WriteLine($"Part 1: {Part1(startPos[0], startPos[1])}");
        Console.WriteLine($"Part 2: {Part2()}");
    }

    static ulong Part1(int p1, int p2)
    {
        return 1;
    }
    static ulong Part2()
    {
        return 1;
    }
}
