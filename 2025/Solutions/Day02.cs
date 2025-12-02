
namespace aoc.Solutions
{

    record Range(ulong Start, ulong End);

    public class Day02
    {
        public static void Solve()
        {
            Range[] records =
                [.. File.ReadAllText("in/d02.txt").Split(',')
                    .Select(x =>
                    {
                        var parts = x.Trim().Split('-').Select(y => ulong.Parse(y)).ToArray();
                        return new Range(parts[0], parts[1]);
                    })];


            Console.WriteLine($"Part 1: {Part1(records)}");
            Console.WriteLine($"Part 2: {Part2(records)}");
        }

        static ulong Part1(Range[] list)
        {
            ulong sum = 0;

            foreach (Range r in list)
            {
                for (ulong i = r.Start; i <= r.End; i++)
                {
                    string s = i.ToString();
                    if (s.Length % 2 != 0) continue;
                    if (s[..(s.Length / 2)] == s[(s.Length / 2)..s.Length])
                    {
                        sum += i;
                    }
                }
            }
            return sum;
        }

        static ulong Part2(Range[] list)
        {
            ulong sum = 0;

            foreach (Range r in list)
            {
                for (ulong i = r.Start; i <= r.End; i++)
                {
                    string s = i.ToString();
                    for (int j = 1; j <= s.Length / 2; j++)
                    {
                        if (s[j..].Replace(s[..j], "").Length == 0)
                        {
                            sum += i;
                            break;
                        }
                    }
                }
            }
            return sum;
        }
    }
}