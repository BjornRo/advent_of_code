using System.Text.RegularExpressions;

namespace aoc.Solutions
{
    public class Day06
    {
        public static void Solve()
        {
            var data = File.ReadAllText("in/d06.txt");

            // Console.WriteLine($"Part 1: {Part1(data)}");
            Console.WriteLine($"Part 2: {Part2(data)}");
        }

        static long Part1(string data)
        {
            var inData = Regex.Replace(data.Trim(), @" +", " ")
                           .Replace("\r\n", "\n")
                           .Split("\n")
                           .Select(x => x.Trim().Split())
                           .ToArray();

            var numberGroups = new Func<long[][]>(() =>
            {
                var matrix = inData[..^1]
                    .Select(x => x.Select(long.Parse).ToArray())
                    .ToArray();

                int rows = matrix.Length;
                int cols = matrix[0].Length;

                var trans = new long[cols][];

                for (int c = 0; c < cols; c++)
                {
                    trans[c] = new long[rows];
                    for (int r = 0; r < rows; r++)
                        trans[c][r] = matrix[r][c];
                }
                return trans;
            })();

            return Aggregator(numberGroups, [.. inData[^1].Select(x => x[0])]); ;
        }

        static long Part2(string data)
        {
            var rawMatrix = data.TrimEnd().Split('\n');

            var numberGroups = new Func<List<List<long>>>(() =>
            {
                var matrix = rawMatrix[..^1];

                int rows = matrix.Length;
                int cols = matrix[0].Length;

                var trans = new char[cols][];

                for (int c = 0; c < cols; c++)
                {
                    trans[c] = new char[rows];
                    for (int r = 0; r < rows; r++)
                    {
                        trans[c][r] = matrix[r][c];
                    }
                }

                List<List<long>> numberGroups = [];
                List<long> groups = [];
                foreach (var row in trans)
                {
                    var result = string.Join("", row).Trim();
                    if (result.Length == 0)
                    {
                        numberGroups.Add(groups);
                        groups = [];
                        continue;
                    }
                    groups.Add(long.Parse(result));
                }
                numberGroups.Add(groups);
                return numberGroups;
            })();

            var operators = rawMatrix[^1].Where(x => !char.IsWhiteSpace(x)).ToArray();

            return Aggregator(numberGroups, operators);
        }

        static long Aggregator(IEnumerable<IEnumerable<long>> numberGroups, char[] operators)
        {
            long total = 0;

            foreach (var (op, numbers) in operators.Zip(numberGroups))
            {
                foreach (var n in numbers)
                {
                    Console.Write($"{n} ");
                }
                Console.WriteLine();
                switch (op)
                {
                    case '*':
                        total += numbers.Aggregate((long)1, (prod, value) => prod * value);
                        break;
                    case '+':
                        total += numbers.Aggregate((long)0, (sum, value) => sum + value);
                        break;
                }
            }

            return total;
        }
    }
}