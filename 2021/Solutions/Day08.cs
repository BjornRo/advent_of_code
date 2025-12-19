namespace aoc.Solutions;

public class Day08
{
    readonly struct Line
    {
        public Line(string raw)
        {
            var r = raw.Split(" | ");
            Signal = [.. r[0].Split(" ").Select(x => x.ToHashSet()).OrderBy(x => x.Count)];
            Output = [.. r[1].Split(" ")];
        }
        public HashSet<char>[] Signal { get; }
        public string[] Output { get; }
        public (HashSet<char>[], string[]) Tuple() => (Signal, Output);

    }
    public static void Solve()
    {
        var lines = File.ReadAllLines("in/d08.txt").Select(x => new Line(x)).ToArray();

        Console.WriteLine($"Part 1: {Part1(lines)}");
        Console.WriteLine($"Part 2: {Part2(lines)}");
    }
    static long Part1(Line[] lines) => lines.Sum(x => x.Output.Sum(y => y.Length is 2 or 4 or 3 or 7 ? 1 : 0));
    static long Part2(Line[] lines)
    {
        long total = 0;
        foreach (var (signal, output) in lines.Select(x => x.Tuple()))
        {
            var one = signal.First(s => s.Count == 2); // 1
            var seven = signal.First(s => s.Count == 3); // 7
            var four = signal.First(s => s.Count == 4); // 4
            var eight = signal.First(s => s.Count == 7); // 8

            var fiveSeg = signal.Where(s => s.Count == 5).ToList(); // 2,3,5
            var three = fiveSeg.First(s => one.All(c => s.Contains(c)));
            fiveSeg.Remove(three);

            var sixSeg = signal.Where(s => s.Count == 6).ToList(); // 0,6,9
            var nine = sixSeg.First(s => four.All(c => s.Contains(c)));
            sixSeg.Remove(nine);

            var zero = sixSeg.First(s => one.All(c => s.Contains(c)));
            sixSeg.Remove(zero);

            var six = sixSeg.First();
            var five = fiveSeg.Single(s => s.All(c => six.Contains(c)));

            var segment = new char[7].ToList();
            segment[0] = seven.Except(one).Single();
            segment[6] = nine.Except(four).Except([segment[0]]).Single();
            segment[3] = three.Except(one).Except([segment[0], segment[6]]).Single();
            segment[1] = four.Except(three).Single();
            segment[5] = one.Intersect(three).Single(six.Contains);
            segment[2] = one.Intersect(three).Single(c => !six.Contains(c));
            segment[4] = eight.Except(nine).Single();

            string number = "";
            foreach (var op in output)
            {
                byte digits = 0;
                foreach (var c in op) digits |= (byte)(1 << segment.IndexOf(c));
                number += digits switch
                {
                    0b010_0100 => '1',
                    0b101_1101 => '2',
                    0b110_1101 => '3',
                    0b010_1110 => '4',
                    0b110_1011 => '5',
                    0b111_1011 => '6',
                    0b010_0101 => '7',
                    0b111_1111 => '8',
                    0b110_1111 => '9',
                    0b111_0111 => '0',
                    _ => throw new Exception(digits.ToString()),
                };
            }
            total += long.Parse(number);
        }
        return total;
    }
}