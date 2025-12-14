using System.Collections.Immutable;
using System.Linq;
using System.Numerics;

namespace aoc.Solutions;

public class Day10
{
    record Row(
        Vector<short> Indicator,
        ImmutableArray<Vector<short>> Buttons,
        Vector<short> JoltReq
    );
    static Vector<short> CreateBtn(short[] arr)
    {
        var v = new short[Vector<short>.Count];
        for (int i = 0; i < arr.Length; i++)
            v[arr[i]] = 1;
        return ToVector(v);
    }
    static Vector<short> ToVector(short[] data)
    {
        if (data.Length >= Vector<short>.Count) return new Vector<short>(data);
        short[] padded = new short[Vector<short>.Count];
        Array.Copy(data, padded, data.Length);
        return new Vector<short>(padded);

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
    static Vector<short> VecMod2(Vector<short> v) => v & Vector<short>.One;
    static int Part1(Row[] list)
    {
        static int Solve(Vector<short> target, ImmutableArray<Vector<short>> buttons)
        {
            Vector<short>[] states = [Vector<short>.Zero];
            int generation = 0;
            while (true)
            {
                List<Vector<short>> next_states = [];
                generation += 1;
                foreach (var state in states)
                    foreach (var button in buttons)
                    {
                        var newState = state + button;
                        if (Vector.EqualsAll(target, VecMod2(newState))) return generation;
                        next_states.Add(newState);
                    }
                states = [.. next_states];
            }
        }
        return list.Aggregate(0, (sum, elem) => sum + Solve(elem.Indicator, elem.Buttons));
    }
    static int Part2(Row[] list)
    {
        // Hint from reddit-aoc, forcing each step to even numbers, then you can halve the search space each step!
        static int Solver(Row elem)
        {
            var (_, buttons, targetJolt) = elem;

            Dictionary<Vector<short>, int> patterns = new() { { Vector<short>.Zero, 0 } };
            void FindPatterns(HashSet<Vector<short>> subPattern, int index)
            {
                for (int i = index; i < buttons.Length; i++)
                {
                    subPattern.Add(buttons[i]);
                    var sum = subPattern.Aggregate(Vector<short>.Zero, (v, b) => v + b);
                    patterns[sum] = Math.Min(patterns.GetValueOrDefault(sum, subPattern.Count), subPattern.Count);
                    FindPatterns(subPattern, i + 1);
                    subPattern.Remove(buttons[i]);
                }
            }
            FindPatterns([], 0);

            Dictionary<Vector<short>, int> visited = [];
            static bool VecEven(Vector<short> v) => Vector.EqualsAll(VecMod2(v), Vector<short>.Zero);
            int BinaryReduction(Vector<short> jState)
            {
                if (visited.TryGetValue(jState, out var result)) return result;
                if (Vector.EqualsAll(Vector<short>.Zero, jState)) return 0;

                int minValue = 9999;
                foreach (var (newState, cost) in patterns.Select(x => (jState - x.Key, x.Value)))
                    if (Vector.LessThanOrEqualAll(Vector<short>.Zero, newState) && VecEven(newState))
                        minValue = Math.Min(minValue, 2 * BinaryReduction(newState / 2) + cost);

                visited[jState] = minValue;
                return minValue;
            }
            return BinaryReduction(targetJolt);
        }
        return list
            .AsParallel()
            .Select(Solver)
            .Aggregate(0, (sum, v) => sum + v);
    }
}
