namespace aoc.Solutions;

public partial class Day25
{
    public static void Solve()
    {
        long[] keys = [.. File.ReadAllLines("in/d25.txt").Select(long.Parse)];
        Console.WriteLine($"Part 1: {Cracker(keys)}");
    }

    static long Cracker(long[] keys)
    {
        long value = 1;
        long i = 0;
        while (true)
        {
            value *= 7;
            value %= 20201227;
            i++;
            if (value == keys[0]) break;
        }

        value = 1;
        for (int j = 0; j < i; j++)
        {
            value *= keys[1];
            value %= 20201227;
        }
        return value;
    }
}
