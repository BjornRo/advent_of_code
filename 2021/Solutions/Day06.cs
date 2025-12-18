namespace aoc.Solutions
{
    public class Day06
    {
        public static void Solve()
        {
            var data = File.ReadAllText("in/d06.txt").TrimEnd().Split(",").Select(sbyte.Parse).ToArray();

            Console.WriteLine($"Part 1: {Part1([.. data])}");
            Console.WriteLine($"Part 2: {Part2([.. data])}");
        }
        static long Part1(List<sbyte> data)
        {
            foreach (var _ in Enumerable.Range(0, 80))
            {
                var len = data.Count;
                for (int i = 0; i < len; i++)
                {
                    data[i] -= 1;
                    if (data[i] != -1) continue;
                    data[i] = 6;
                    data.Add(8);
                }
            }
            return data.Count;
        }
        static long Part2(List<sbyte> data, int days = 256)
        {
            var numbers = data.Aggregate(new long[9], (agg, v) => { agg[v] += 1; return agg; }).ToList();
            var newNumbers = new long[numbers.Count].ToList();
            foreach (var _ in Enumerable.Range(0, days))
            {
                var tmp = numbers[0];
                for (int i = 1; i < numbers.Count; i++)
                {
                    newNumbers[i - 1] = numbers[i];
                    numbers[i] = 0;
                }
                newNumbers[6] += tmp;
                newNumbers[8] += tmp;
                (numbers, newNumbers) = (newNumbers, numbers);
            }
            return numbers.Sum();
        }
    }
}