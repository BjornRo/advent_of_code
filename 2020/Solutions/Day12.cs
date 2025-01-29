using System.Numerics;

namespace aoc.Solutions;

public class Day12
{
    enum Action
    {
        North = 'N',
        South = 'S',
        East = 'E',
        West = 'W',
        Left = 'L',
        Right = 'R',
        Forward = 'F',
    }

    readonly struct Steps(in string value)
    {
        public readonly Action Action = (Action)value[0];
        public readonly int Value = int.Parse(value[1..]);
    }

    public static void Solve()
    {
        Steps[] steps = [.. File.ReadAllLines("in/d12.txt").Select(line => new Steps(line))];

        Console.WriteLine($"Part 1: {Part1(steps)}");
        // Console.WriteLine($"Part 2: {Part2([.. matrix.Select(row => row.ToCharArray())])}");
    }

    static long Part1(in Steps[] steps)
    {
        var direction = new Complex(0, 1);
        var position = new Complex(0, 0);

        foreach (var step in steps)
        {
            switch (step.Action)
            {
                case Action.South:
                    position += new Complex(step.Value, 0);
                    break;
                case Action.North:
                    position += new Complex(-step.Value, 0);
                    break;
                case Action.West:
                    position += new Complex(0, -step.Value);
                    break;
                case Action.East:
                    position += new Complex(0, step.Value);
                    break;
                case Action.Left:
                    for (int i = 0; i < step.Value; i += 90) direction *= new Complex(0, 1);
                    break;
                case Action.Right:
                    for (int i = 0; i < step.Value; i += 90) direction *= new Complex(0, -1);
                    break;
                case Action.Forward:
                    position += direction * step.Value;
                    break;
            }
        }
        long row = (long)position.Real, col = (long)position.Imaginary;
        return long.Abs(row) + long.Abs(col);
    }

}
