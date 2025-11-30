namespace aoc.Solutions
{
    public class Day01
    {
        public static void Solve()
        {
            string[] lines = File.ReadAllLines("in/d01.txt");

            List<int> list = [];
            foreach (var line in lines)
            {
                if (int.TryParse(line, out int num))
                {
                    list.Add(num);
                }
            }

            Console.WriteLine($"Part 1: {Part1(list)}");
            Console.WriteLine($"Part 2: {Part2(list)}");
        }

        static int Part1(in List<int> list)
        {
            int count = 0;
            int last = int.MaxValue;
            foreach (int value in list)
            {
                if (value > last)
                {
                    count += 1;
                }
                last = value;
            }
            return count;
        }

        static int Part2(in List<int> list)
        {
            List<int> new_list = [];

            for (int i = 0; i < list.Count - 2; i++)
            {
                new_list.Add(list[i] + list[i + 1] + list[i + 2]);
            }

            return Part1(new_list);
        }

    }
}