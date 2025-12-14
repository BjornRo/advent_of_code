using System.Collections.Immutable;
using System.Linq;
using System.Numerics;

namespace aoc.Solutions;

using Vec = Vector<short>;
public class Day10
{
    record Row(
        Vec Indicator,
        ImmutableArray<Vec> Buttons,
        Vec JoltReq
    );
    static Vec CreateBtn(short[] arr)
    {
        var v = new short[Vec.Count];
        for (int i = 0; i < arr.Length; i++) v[arr[i]] = 1;
        return ToVector(v);
    }
    static Vec ToVector(short[] data)
    {
        short[] padded = new short[Vec.Count];
        Array.Copy(data, padded, data.Length);
        return new Vec(padded);

    }
    static Row Parse(string row)
    {
        var s = row.Split();
        var ind = ToVector([.. s[0][1..^1].Select(x => (short)(x == '#' ? 1 : 0))]);
        var buttons = s[1..^1].Select(
            x => x[1..^1]
                .Split(",")
                .Select(short.Parse)
                .ToArray()
            )
            .Select(CreateBtn)
            .ToImmutableArray();
        short[] joltReqRaw = [.. s[^1][1..^1].Split(",").Select(short.Parse)];
        var joltreq = ToVector(joltReqRaw);
        return new Row(ind, buttons, joltreq);
    }
    public static void Solve()
    {
        Row[] list = [.. File.ReadAllLines("in/d10.txt").Select(Parse)];

        Console.WriteLine($"Part 1: {Part1(list)}");
        Console.WriteLine($"Part 2: {Part2(list)}");
    }
    static Vec VecMod2(Vec v) => v & Vec.One;
    static int Part1(Row[] list)
    {
        static int Solver(Row elem)
        {
            Vec[] states = [Vec.Zero];
            int generation = 0;
            while (true)
            {
                List<Vec> next_states = [];
                generation += 1;
                foreach (var state in states)
                    foreach (var button in elem.Buttons)
                    {
                        var newState = state + button;
                        if (Vector.EqualsAll(elem.Indicator, VecMod2(newState))) return generation;
                        next_states.Add(newState);
                    }
                states = [.. next_states];
            }
        }
        return list.Sum(Solver);
    }
    // Hint from reddit-aoc, forcing each step to even numbers, then you can halve the search space each step!
    static int Part2(Row[] list)
    {
        static int Solver(Row elem)
        {
            Dictionary<Vec, int> patterns = new() { { Vec.Zero, 0 } };
            void FindPatterns(HashSet<Vec> subPattern, int index)
            {
                for (int i = index; i < elem.Buttons.Length; i++)
                {
                    subPattern.Add(elem.Buttons[i]);
                    var sum = subPattern.Aggregate(Vec.Zero, (v, b) => v + b);
                    patterns[sum] = Math.Min(patterns.GetValueOrDefault(sum, subPattern.Count), subPattern.Count);
                    FindPatterns(subPattern, i + 1);
                    subPattern.Remove(elem.Buttons[i]);
                }
            }
            FindPatterns([], 0);

            Dictionary<Vec, int> visited = [];
            static bool VecEven(Vec v) => Vector.EqualsAll(VecMod2(v), Vec.Zero);
            int BinaryReduction(Vec jState)
            {
                if (visited.TryGetValue(jState, out var result)) return result;
                if (Vector.EqualsAll(Vec.Zero, jState)) return 0;

                int minValue = 9999;
                foreach (var (newState, cost) in patterns.Select(x => (jState - x.Key, x.Value)))
                    if (Vector.LessThanOrEqualAll(Vec.Zero, newState) && VecEven(newState))
                        minValue = Math.Min(minValue, 2 * BinaryReduction(newState / 2) + cost);

                return visited[jState] = minValue;
            }
            return BinaryReduction(elem.JoltReq);
        }
        return list
            .AsParallel()
            .Sum(Solver);
    }
}
