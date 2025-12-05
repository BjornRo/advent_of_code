using System.Collections.Immutable;

namespace aoc.Solutions
{
    public class Day05
    {
        record Range(ulong Start, ulong End);
        public static void Solve()
        {
            var (ranges, ingredients) = new Func<(ImmutableArray<Range>, ImmutableArray<ulong>)>(() =>
            {
                string data = File.ReadAllText("in/d05.txt").Replace("\r\n", "\n").TrimEnd();
                string[] range_map = data.Split("\n\n");

                var ranges = range_map[0]
                    .Split("\n")
                    .Select(row =>
                    {
                        var res = row.Split("-").Select(x => ulong.Parse(x)).ToArray();
                        return new Range(res[0], res[1]);
                    })
                    .ToImmutableArray();

                var ingredients = range_map[1]
                    .Split("\n")
                    .Select(x => ulong.Parse(x))
                    .ToImmutableArray();

                return (ranges, ingredients);
            })();

            Console.WriteLine($"Part 1: {Part1(ranges, ingredients)}");
            Console.WriteLine($"Part 2: {Part2(ranges)}");
        }
        static ulong Part1(ImmutableArray<Range> ranges, ImmutableArray<ulong> ingredients)
        {
            ulong freshness = 0;

            foreach (var ingredient in ingredients)
            {
                foreach (var range in ranges)
                {
                    if (range.Start <= ingredient && ingredient <= range.End)
                    {
                        freshness += 1;
                        break;
                    }
                }
            }


            return freshness;
        }

        static ulong Part2(ImmutableArray<Range> ranges)
        {
            ulong freshness = 0;

            var a = ranges.ToList();

            while (true)
            {
                bool[] flags = new bool[a.Count];
                List<Range> b = [];

                for (int i = 0; i < a.Count; i++)
                {
                    if (flags[i]) continue;

                    var (start, end) = a[i];
                    for (int j = i + 1; j < a.Count; j++)
                    {
                        if (flags[j]) continue;

                        var (_start, _end) = a[j];
                        if (start <= _start && _start <= end)
                        {
                            end = ulong.Max(_end, end);
                            flags[j] = true;
                        }
                        if (start <= _end && _end <= end)
                        {
                            start = ulong.Min(_start, start);
                            flags[j] = true;
                        }
                    }
                    b.Add(new(start, end));
                }

                if (flags.All(x => !x))
                {
                    a = b;
                    break;
                }
                a = b;
                a.Reverse(); // THIS SOLVES IT... Yay bug somewhere :D
            }

            foreach (var range in a)
            {
                Console.WriteLine($"{range.Start},{range.End}");
                freshness += range.End - range.Start + 1;
            }

            return freshness;
        }
    }
}