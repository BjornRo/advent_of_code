using System.Collections.Immutable;
using System.Text;

namespace aoc.Solutions;

public class Day14
{
    public static void Solve()
    {
        var data = File.ReadAllText("in/d14.txt").TrimEnd().Replace("\r\n", "\n").Split("\n\n");
        var template = data[0].Trim().Select(c => (byte)c).ToArray();
        var rules = data[1]
            .Split("\n")
            .Select(r => r.Split(" -> "))
            .ToImmutableDictionary(e => ((byte)e[0][0], (byte)e[0][1]), e => (byte)e[1][0]);

        Console.WriteLine($"Part 1: {Part1([.. template], rules)}");
        Console.WriteLine($"Part 2: {Part2(template, rules)}");
    }
    static int Part1(List<byte> template, ImmutableDictionary<(byte, byte), byte> rules)
    {
        List<byte> tmpTemp = [];
        foreach (var _ in Enumerable.Range(1, 10))
        {
            for (int i = 0; i < template.Count - 1; i++)
            {
                var subStr = (template[i], template[i + 1]);
                tmpTemp.Add(template[i]);
                if (rules.TryGetValue(subStr, out var result))
                {
                    tmpTemp.Add(result);
                    continue;
                }
                tmpTemp.Add(template[i + 1]);
            }
            tmpTemp.Add(template[^1]);
            (template, tmpTemp) = (tmpTemp, template);
            tmpTemp.Clear();
        }
        var counts = template.Aggregate(new Dictionary<byte, int>(), (agg, b) =>
            { agg[b] = agg.GetValueOrDefault(b) + 1; return agg; }).Values;
        return counts.Max() - counts.Min();
    }
    static ulong Part2(byte[] template, ImmutableDictionary<(byte, byte), byte> rules)
    {
        Dictionary<(byte, byte), ulong> occurrences = [];
        for (int i = 0; i < template.Length - 1; i++)
        {
            var subStr = (template[i], template[i + 1]);
            occurrences[subStr] = occurrences.GetValueOrDefault(subStr) + 1;
        }
        foreach (var _ in Enumerable.Range(1, 40))
            occurrences = occurrences.Aggregate((Dictionary<(byte, byte), ulong>)[], (agg, kv) =>
            {
                if (rules.TryGetValue(kv.Key, out var result))
                    foreach (var subStr in new[] { (kv.Key.Item1, result), (result, kv.Key.Item2) })
                        agg[subStr] = agg.GetValueOrDefault(subStr) + kv.Value;
                else agg[kv.Key] += kv.Value;
                return agg;
            });

        var values = occurrences.Aggregate(new Dictionary<byte, ulong>() { { template[^1], 1UL } }, (agg, kv) =>
            { agg[kv.Key.Item1] = agg.GetValueOrDefault(kv.Key.Item1) + kv.Value; return agg; }).Values;
        return values.Max() - values.Min();
    }
}
