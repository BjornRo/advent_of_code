namespace aoc.Solutions;

public class Day15
{
    public static void Solve()
    {
        int[] data = File.ReadAllText("in/d15.txt").TrimEnd().Split(',').Select(int.Parse).ToArray();

        Console.WriteLine($"Part 1: {Solver(data, 2020)}");
        Console.WriteLine($"Part 2: {Solver(data, 30_000_000)}");
    }

    static int Solver(in int[] data, int nthNumber)
    {
        Dictionary<int, int> spoken = [];
        int i = 1;
        for (; i <= data.Length; i++) spoken[data[i - 1]] = i;
        int lastSpoken = 0;
        for (; i < nthNumber; i++)
            if (spoken.TryGetValue(lastSpoken, out int value))
            {
                spoken[lastSpoken] = i;
                lastSpoken = i - value;
            }
            else
            {
                spoken[lastSpoken] = i;
                lastSpoken = 0;
            }

        return lastSpoken;
    }
}
