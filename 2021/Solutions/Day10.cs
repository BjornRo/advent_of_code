namespace aoc.Solutions;

public class Day10
{
    public static void Solve()
    {
        string[] lines = File.ReadAllLines("in/d10.txt");

        var result = ValidLines(lines);
        Console.WriteLine($"Part 1: {result.Sum(x => x.Item2)}");
        Console.WriteLine($"Part 2: {Part2([.. result.Where(x => x.Item2 == 0).Select(x => x.Item1)])}");
    }
    static (string, int)[] ValidLines(string[] lines) => [.. lines.Select(line =>
        {
            while (true)
            {
                var len = line.Length;
                line = line.Replace("[]", "").Replace("{}", "").Replace("()", "").Replace("<>", "");
                if (line.Length == len) break;
            }
            int valid = 0;
            foreach (var c in line)
            {
                valid = c switch
                {
                    ')' => 3,
                    ']' => 57,
                    '}' => 1197,
                    '>' => 25137,
                    _ => 0,
                };
                if (valid != 0) break;
            }
            return (line, valid);
        })];

    static long Part2(string[] lines) =>
        lines.Select(line =>
            line
                .Reverse()
                .Aggregate(0L, (agg, c) => agg * 5 + c switch
                {
                    '(' => 1,
                    '[' => 2,
                    '{' => 3,
                    _ => 4,
                }
                )
        ).OrderBy(x => x).ElementAt(lines.Length / 2);
}
