using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day10
{
    record Row(
        ImmutableArray<bool> Indicator,
        ImmutableArray<ImmutableArray<int>> Buttons,
        ImmutableArray<uint> JoltReq
    );
    static Row Parse(string row)
    {
        var s = row.Split();
        var ind = s[0][1..^1].Select(x => x == '#').ToImmutableArray();
        var wiring = s[1..^1].Select(
            x => x[1..^1]
                .Split(",")
                .Select(int.Parse)
                .ToImmutableArray()
            )
            .OrderBy(x => -x.Length)
            .ToImmutableArray();
        var joltreq = s[^1][1..^1].Split(",").Select(uint.Parse).ToImmutableArray();
        return new Row(ind, wiring, joltreq);
    }
    public static void Solve()
    {
        Row[] list = [.. File.ReadAllLines("in/d10t.txt").Select(Parse)];

        // Console.WriteLine($"Part 1: {Part1(list)}");
        Console.WriteLine($"Part 2: {Part2x(list)}");
    }
    static int Part2x(Row[] list)
    {
        static int Solver(Row elem)
        {
            var (target, buttons, joltages) = elem;
            var maxPresses = buttons.Select(v => v.Min(i => joltages[i])).ToArray();
            var maxTotalPresses = joltages.Max();

            HashSet<uint[]> visited = [];

            uint? Rec(uint presses, bool[] iState, uint[] jState, uint[] pState)
            {
                if (!visited.Add(pState)) return uint.MaxValue;
                // Print(iState);
                // Print(jState);
                // Console.WriteLine(presses);
                // Console.WriteLine();
                if (iState.SequenceEqual(target) && jState.SequenceEqual(joltages)) return presses;

                foreach (var (btn, k) in buttons.Select((x, i) => (x, i)))
                {
                    bool[] new_iState = [.. iState];
                    uint[] new_jState = [.. jState];
                    if (pState[k] >= maxPresses[k]) continue;

                    uint[] new_pState = [.. pState];
                    new_pState[k] += 1;
                    foreach (var i in btn)
                    {
                        new_iState[i] = !new_iState[i];
                        new_jState[i] += 1;
                    }
                    if (new_jState.Zip(joltages, (a, b) => a > b).Any(x => x)) continue;
                    if (Rec(presses + 1, new_iState, new_jState, new_pState) is uint res)
                    {
                        if (res != uint.MaxValue)
                            return res;
                    }
                }
                return uint.MaxValue;
            }

            Console.WriteLine(Rec(0, new bool[target.Length], new uint[joltages.Length], new uint[buttons.Length]));
            return 0;

        }
        return list.Aggregate(0, (sum, elem) => sum + Solver(elem));
    }
    static int Part1(Row[] list)
    {
        static int Solver(Row elem)
        {
            var (target, buttons, _) = elem;
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
        return list.Aggregate(0, (sum, elem) => sum + Solver(elem));
    }
    record P2State(bool[] IState, uint[] JState, uint[] Presses);
    static int Part2(Row[] list)
    {
        static int Solver(Row elem)
        {
            var (target, buttons, joltages) = elem;

            var maxPresses = buttons.Select(v => v.Min(i => joltages[i])).ToArray();

            HashSet<uint[]> visited = [];

            P2State[] states = [
                new P2State(new bool[target.Length], new uint[joltages.Length], new uint[buttons.Length])
                ];
            int generation = 0;
            while (states.Length != 0)
            {
                List<P2State> next_states = [];
                generation += 1;
                foreach (var (iState, jState, pushed) in states)
                {
                    foreach (var (presses, k) in buttons.Select((x, i) => (x, i)))
                    {
                        bool[] new_iState = [.. iState];
                        uint[] new_jState = [.. jState];
                        if (pushed[k] >= maxPresses[k]) continue;

                        uint[] new_pState = [.. pushed];
                        new_pState[k] += 1;
                        if (visited.Contains(new_pState)) continue;
                        foreach (var i in presses)
                        {
                            new_iState[i] = !new_iState[i];
                            new_jState[i] += 1;
                        }
                        if (new_iState.SequenceEqual(target) && new_jState.SequenceEqual(joltages))
                        {
                            return generation;
                        }
                        if (!new_jState.Zip(joltages, (a, b) => a > b).Any(x => x))
                        {
                            Console.WriteLine(generation);
                            Print(new_jState);
                            Print(joltages.ToArray());
                            // Console.WriteLine(new_jState.Zip(joltages, (a, b) => a > b).Any(x => x));
                            Console.WriteLine();
                            // Print(new_jState);
                            // Print(joltages.ToArray());
                            // Console.WriteLine();
                            visited.Add(new_pState);
                            next_states.Add(new P2State(new_iState, new_jState, new_pState));

                        }
                    }
                }
                states = [.. next_states];
            }
            throw new Exception("Not here");
        }
        return list.Aggregate(0, (sum, elem) => sum + Solver(elem));
    }
    static void Print<T>(T[] array)
    {
        Console.Write("[");
        for (int i = 0; i < array.Length; i++)
        {
            Console.Write(array[i]);
            if (i < array.Length - 1)
                Console.Write(", ");
        }
        Console.WriteLine("]");
    }
}
