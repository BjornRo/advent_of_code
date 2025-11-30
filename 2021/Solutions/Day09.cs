namespace aoc.Solutions;

public class Day09
{
    public static void Solve()
    {
        long[] list = [.. File.ReadAllLines("in/d09.txt").Select(long.Parse)];

        Console.WriteLine($"Part 1: {PatternFinder(list, 25)}");
        Console.WriteLine($"Part 2: {WeaknessFinder(list, 25)}");
    }

    static long PatternFinder(long[] list, int preamble)
    {
        for (int i = 0; i < list.Length - preamble - 1; i++)
        {
            long target = list[i + preamble];
            long[] subList = list[i..(i + preamble + 1)];
            bool valid = false;
            for (int j = 0; j < subList.Length - 1; j++)
            {
                for (int k = j + 1; k < subList.Length - 1; k++)
                    if (subList[j] + subList[k] == target)
                    {
                        valid = true;
                        break;
                    }
                if (valid) break;
            }
            if (!valid) return target;
        }
        return 0;
    }

    static long WeaknessFinder(long[] list, int preamble)
    {
        long target = PatternFinder(list, preamble);
        for (int i = 0; i < list.Length - 1; i++)
        {
            long min = list[i];
            long max = list[i];
            long total = list[i];

            for (int j = i + 1; j < list.Length; j++)
            {
                var nextValue = list[j];
                if (nextValue > max) max = nextValue;
                else if (nextValue < min) min = nextValue;

                total += nextValue;
                if (total == target) return min + max;
                if (total > target) break;
            }
        }
        return 0;
    }
}
