namespace aoc.Solutions;

public class Day10
{
    public static void Solve()
    {
        List<int> list = [.. File.ReadAllLines("in/d10.txt").Select(int.Parse)];
        list.Sort();

        Console.WriteLine($"Part 1: {Part1(list)}");
        Console.WriteLine($"Part 2: {Part2(list, 0, 0, [])}");
    }

    static int Part1(in List<int> list)
    {
        int jolt = 0;
        int diff1 = 0;
        int diff3 = 1;
        foreach (var nextAdapter in list)
        {
            var diff = nextAdapter - jolt;
            if (diff == 1) diff1 += 1;
            else if (diff == 3) diff3 += 1;
            jolt = nextAdapter;
        }
        return diff1 * diff3;
    }

    static long Part2(in List<int> list, int jolt, int index, Dictionary<(int, int), long> memo)
    {
        if (memo.TryGetValue((jolt, index), out long value)) return value;
        if (index == list.Count) return 1;

        long total = 0;
        for (int i = index; i < list.Count; i++)
        {
            var nextAdapter = list[i];
            if (nextAdapter - jolt > 3) break;
            total += Part2(list, nextAdapter, i + 1, memo);
        }
        memo[(jolt, index)] = total;

        return total;
    }
}
