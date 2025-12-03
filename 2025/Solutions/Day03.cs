namespace aoc.Solutions
{
    public class Day03
    {
        public static void Solve()
        {
            string[] rows = File.ReadAllLines("in/d03.txt");

            Console.WriteLine($"Part 1: {Part1(rows)}");
            Console.WriteLine($"Part 2: {Part2(rows)}");
        }

        static ulong Part1(string[] rows)
        {
            ulong sum = 0;
            foreach (string row in rows)
            {
                List<uint> jolts = [];
                for (int i = 0; i < row.Length - 1; i++)
                {
                    for (int j = i + 1; j < row.Length; j++)
                    {
                        jolts.Add(uint.Parse($"{row[i]}{row[j]}"));
                    }
                }
                sum += jolts.Max();
            }
            return sum;
        }


        static ulong Part2(string[] rows) =>
            rows.Aggregate((ulong)0, (sum, row) => sum + ulong.Parse(Jolter(row, 0, 12 - 1)));

        static string Jolter(string row, int index, int remaining)
        {
            if (remaining == -1) return "";
            var max_index = index;
            var max_value = row[index];

            for (int i = index; i < row.Length - remaining; i++)
            {
                if (row[i] > max_value)
                {
                    max_value = row[i];
                    max_index = i;
                }
            }
            return row[max_index] + Jolter(row, max_index + 1, remaining - 1);
        }
    }
}