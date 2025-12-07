using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day07
{

    enum Elem
    {
        Dot = '.',
        Split = '^',
        Start = 'S',
    }
    public static void Solve()
    {
        var data = File.ReadAllText("in/d07.txt")
            .TrimEnd()
            .Split()
            .Select(x => x.Select(c => c switch
                {
                    '.' => Elem.Dot,
                    '^' => Elem.Split,
                    'S' => Elem.Start,
                    _ => throw new NotImplementedException()
                }
                ).ToImmutableArray()
            ).ToImmutableArray();


        Console.WriteLine($"Part 1: {Part1(data)}");
        Console.WriteLine($"Part 2: {Part2(data, (1, data[0].IndexOf(Elem.Start)))}");
    }

    static int Part1(ImmutableArray<ImmutableArray<Elem>> data)
    {
        // Row, col
        HashSet<(int, int)> visited = [];
        Stack<(int, int)> stack = new([(1, data[0].IndexOf(Elem.Start))]);

        int count = 0;

        while (stack.TryPop(out var result))
        {
            var (row, col) = result;
            if (!(0 <= row && row < data.Length && 0 <= col && col < data[0].Length)) continue;

            if (data[row][col] == Elem.Split)
            {
                stack.Push((row + 1, col - 1));
                stack.Push((row + 1, col + 1));
                count += 1;
                continue;
            }

            if (visited.Contains(result)) continue;
            visited.Add(result);

            stack.Push((row + 1, col));
        }

        return count;
    }

    static readonly Dictionary<(int, int), long> memo = [];
    static long Part2(ImmutableArray<ImmutableArray<Elem>> data, (int, int) position)
    {
        long count = 0;
        var (row, col) = position;
        while (true)
        {
            if (!(0 <= row && row < data.Length))
            {
                return count + 1;
            }
            if (data[row][col] == Elem.Split)
            {
                checked
                {
                    if (memo.TryGetValue((row, col), out var value))
                    {
                        count += value;
                    }
                    else
                    {
                        var res = Part2(data, (row + 1, col + 1));
                        memo.Add((row, col), res);
                        count += res;
                    }
                }
                col -= 1;
            }
            row += 1;
        }
    }
}
