namespace aoc.Solutions
{
    public class Day03
    {
        public static void Solve()
        {
            var rows = File.ReadAllLines("in/d03.txt").Select(s => s.ToCharArray()).ToArray();

            Console.WriteLine($"Part 1: {Part1(rows)}");
            Console.WriteLine($"Part 2: {Part2(rows)}");
        }
        static long ArrToLong(int[] arr) => arr.Aggregate(0, (agg, bit) => (agg << 1) | (bit <= 0 ? 0 : 1));
        static long Part1(char[][] data)
        {
            long gamma = ArrToLong(data.Aggregate(new int[data[0].Length],
                (agg, row) => [.. agg.Zip(row, (a, b) => a + (b == '0' ? -1 : 1))]
            ));
            checked { return gamma * (~gamma & ((1 << data[0].Length) - 1)); }
        }
        static long Part2(char[][] data)
        {
            static long F(char[][] reduced, bool oxygen)
            {
                var (a, b) = oxygen ? ('1', '0') : ('0', '1');
                foreach (var i in Enumerable.Range(0, int.MaxValue))
                {
                    var res = 0 <= reduced.Aggregate(0, (agg, row) => agg + (row[i] == '0' ? -1 : 1));
                    reduced = [.. reduced.Where(x => (res && x[i] == a) || (!res && x[i] == b))];
                    if (reduced.Length == 1) break;
                }
                return ArrToLong([.. reduced[0].Select(x => x - '0')]);
            }
            checked { return F(data, true) * F(data, false); }
        }
    }
}