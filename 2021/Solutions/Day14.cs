using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day14
{
    public static void Solve()
    {
        var data = File.ReadAllText("in/d14.txt").TrimEnd().Replace("\r\n", "\n").Split("\n\n");
        var template = data[0].Trim();
        var rules = data[1].Split("\n").Select(r => r.Split(" -> ")).ToImmutableDictionary(e => e[0], e => e[1]);

        Console.WriteLine($"Part 1: {Part1(template, rules)}");
        Console.WriteLine($"Part 2: {Part2(template, rules)}");
    }
    static int Part1(string template, ImmutableDictionary<string, string> rules)
    {
        foreach (var _ in Enumerable.Range(1, 10))
        {
            var tmpTemp = "";
            for (int i = 0; i < template.Length - 1; i++)
            {
                var subStr = template[i..(i + 2)];
                tmpTemp += subStr[0];
                if (rules.TryGetValue(subStr, out var result))
                {
                    tmpTemp += result;
                    continue;
                }
                tmpTemp += subStr[1];
            }
            template = tmpTemp + template[^1];
        }
        var counts = new Dictionary<char, int>();
        foreach (var c in template) counts[c] = counts.GetValueOrDefault(c) + 1;
        return counts.Values.Max() - counts.Values.Min();
    }
    static ulong Part2(string template, ImmutableDictionary<string, string> rules)
    {
        Dictionary<string, ulong> occurrences = [];
        for (int i = 0; i < template.Length - 1; i++)
        {
            var subStr = template[i..(i + 2)];
            occurrences[subStr] = occurrences.GetValueOrDefault(subStr) + 1;
        }
        foreach (var _ in Enumerable.Range(1, 40))
            occurrences = occurrences.Aggregate((Dictionary<string, ulong>)[], (agg, kv) =>
            {
                if (rules.TryGetValue(kv.Key, out var result))
                    foreach (var subStr in new[] { kv.Key[0] + result, result + kv.Key[1] })
                        agg[subStr] = agg.GetValueOrDefault(subStr) + kv.Value;
                else agg[kv.Key] += kv.Value;
                return agg;
            });

        var values = occurrences.Aggregate(new Dictionary<char, ulong>() { { template[^1], 1UL } }, (agg, kv) =>
            { agg[kv.Key[0]] = agg.GetValueOrDefault(kv.Key[0]) + kv.Value; return agg; }).Values;
        return values.Max() - values.Min();
    }
}
