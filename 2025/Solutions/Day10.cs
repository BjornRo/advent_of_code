using System.Collections.Immutable;
using System.Numerics;

namespace aoc.Solutions;

public class Day10
{
    record Row(
        ImmutableArray<bool> Indicator,
        ImmutableArray<Vector<short>> Buttons,
        Vector<short> JoltReq,
        byte JoltLen
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
        var ind = s[0][1..^1].Select(x => x == '#').ToImmutableArray();
        var buttons = s[1..^1].Select(
            x => x[1..^1]
                .Split(",")
                .Select(short.Parse)
                .ToArray()
            )
            .OrderBy(x => x.Length)
            .Select(CreateBtn)
            .ToImmutableArray();
        short[] joltReqRaw = [.. s[^1][1..^1].Split(",").Select(short.Parse)];
        var joltreq = ToVector(joltReqRaw);
        return new Row(ind, buttons, joltreq, (byte)joltReqRaw.Length);
    }
    public static void Solve()
    {
        Row[] list = [.. File.ReadAllLines("in/d10.txt").Select(Parse)];

        // Console.WriteLine($"Part 1: {Part1(list)}");
        Console.WriteLine($"Part 2: {Part2z(list)}");
    }

    static int Part2z(Row[] list)
    {
        static short[] Solver(Row elem)
        {
            var (_, buttons, joltages, _) = elem;
            short maxJolt = 0;
            for (int i = 0; i < Vector<short>.Count; i++) maxJolt = short.Max(maxJolt, joltages[i]);

            short[]? Backtrack(short[] presses, int pIndex, Vector<short> jState)
            {
                if (Vector.EqualsAll(jState, joltages)) return presses;
                if (pIndex >= buttons.Length) return null;

                for (byte i = 0; i <= maxJolt; i++)
                {
                    var new_jState = jState + buttons[pIndex] * i;
                    if (!Vector.GreaterThanOrEqualAll(joltages, new_jState)) break;

                    presses[pIndex] = i;
                    var res = Backtrack(presses, pIndex + 1, new_jState);
                    if (res != null) return res;
                    presses[pIndex] = 0;
                }
                return null;
            }

            var res = Backtrack(new short[buttons.Length], 0, Vector<short>.Zero) ??
                throw new Exception("null found");
            // Print(res);
            // Console.WriteLine();
            return res;
        }
        return list
            .Select((x, i) => (x, i + 1))
            .OrderBy(x => -CountNonZero(x.x.JoltReq))
            .AsParallel()
            .WithDegreeOfParallelism(8)
            .Select(row =>
                {
                    if (cache.TryGetValue(row.Item2, out var result)) return result;

                    var res = Solver(row.x);
                    var value = res.Aggregate(0, (sum, press) => sum + press);
                    Console.WriteLine($"{row.Item2} | {value} | {FmtA(res)}");
                    return value;
                })
            .Aggregate(0, (sum, v) => sum + v);
    }
    static readonly Dictionary<int, int> cache = new()
    {
        { 45, 63 }, // [2, 13, 8, 4, 17, 12, 1, 0, 5, 1]
        // { 9, 80 },
        // {10, 51}
    };
    record P2State(byte[] JState, byte[] Presses);
    // static int Part2(Row[] list)
    // {
    //     static int Solver(Row elem)
    //     {
    //         var (target, buttons, joltages) = elem;
    //         var maxPresses = buttons.Select(v => v.Min(i => joltages[i])).ToArray();

    //         P2State[] states = [new P2State(new byte[joltages.Length], new byte[buttons.Length])];
    //         int generation = 0;
    //         while (states.Length != 0)
    //         {
    //             List<P2State> next_states = [];
    //             generation += 1;
    //             foreach (var (jState, pState) in states)
    //             {
    //                 foreach (var (presses, k) in buttons.Select((x, i) => (x, i)))
    //                 {
    //                     byte[] new_jState = [.. jState];
    //                     byte[] new_pState = [.. pState];
    //                     new_pState[k] += 1;
    //                     if (new_pState[k] > maxPresses[k]) continue;

    //                     foreach (var i in presses)
    //                     {
    //                         new_jState[i] += 1;
    //                     }

    //                     if (new_jState.SequenceEqual(joltages))
    //                     {
    //                         return generation;
    //                     }
    //                     if (!new_jState.Zip(joltages, (a, b) => a > b).Any(x => x))
    //                     {
    //                         // Console.WriteLine(generation);
    //                         // Print(new_jState);
    //                         // Print(joltages.ToArray());
    //                         // Console.WriteLine(new_jState.Zip(joltages, (a, b) => a > b).Any(x => x));
    //                         // Console.WriteLine();
    //                         // Print(new_jState);
    //                         // Print(joltages.ToArray());
    //                         // Console.WriteLine();
    //                         next_states.Add(new P2State(new_jState, new_pState));

    //                     }
    //                 }
    //             }
    //             states = [.. next_states];
    //         }
    //         throw new Exception("Not here");
    //     }
    //     var res = list
    //         .AsParallel()
    //         .Select(r =>
    //             {
    //                 var x = Solver(r);
    //                 Console.WriteLine(x);
    //                 return x;
    //             });
    //     return res.Aggregate(0, (sum, e) => sum + e);
    // }
    static string FmtA<T>(T[] array) => $"[{string.Join(", ", array)}]";

    static string FmtV<T>(Vector<T> v) where T : struct
    {
        T[] arr = new T[Vector<T>.Count];
        v.CopyTo(arr);
        return $"[{string.Join(", ", arr)}]";
    }
    static int CountNonZero<T>(Vector<T> v) where T : struct, IEquatable<T>
    {
        T[] arr = new T[Vector<T>.Count];
        v.CopyTo(arr);

        int count = 0;
        foreach (var x in arr) if (!x.Equals(default)) count++;
        return count;
    }
}
