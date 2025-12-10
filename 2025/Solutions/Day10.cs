using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day10
{
    record Row(ImmutableArray<bool> Indicator, int[][] Buttons, int[] JoltReq);
    static Row Parse(string row)
    {
        var s = row.Split();
        var ind = s[0][1..^1].Select(x => x == '#').ToImmutableArray();
        var wiring = s[1..^1].Select(x => x[1..^1].Split(",").Select(int.Parse).ToArray()).ToArray();
        var joltreq = s[^1][1..^1].Split(",").Select(int.Parse).ToArray();
        return new Row(ind, wiring, joltreq);
    }
    public static void Solve()
    {
        Row[] list = [.. File.ReadAllLines("in/d10.txt").Select(Parse)];

        Console.WriteLine($"Part 1: {Part1(list)}");
        // Console.WriteLine($"Part 2: {Part2(list, 0, 0, [])}");
    }

    // record State(bool[] lights)
    static int Part1Solve(ImmutableArray<bool> target, int[][] buttons)
    {
        bool[][] states = [new bool[target.Length]];
        int generation = 0;
        while (true)
        {
            List<bool[]> next_states = [];
            generation += 1;
            foreach (var state in states)
            {
                foreach (var presses in buttons)
                {
                    bool[] new_state = [.. state];
                    foreach (var i in presses)
                    {
                        new_state[i] = !new_state[i];
                    }
                    if (new_state.SequenceEqual(target))
                    {
                        return generation;
                    }
                    next_states.Add(new_state);
                }
            }
            states = [.. next_states];
        }
    }

    static int Part1(Row[] list)
    {
        return list.Aggregate(0, (sum, elem) => sum + Part1Solve(elem.Indicator, elem.Buttons));
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
