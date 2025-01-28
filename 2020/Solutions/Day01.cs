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
                    list.Add(num);
            }

            Console.WriteLine($"Part 1: {Part1(list)}");
            Console.WriteLine($"Part 2: {Part2(list)}");
        }

        static int Part1(List<int> list)
        {
            for (int i = 0; i < list.Count - 1; i++)
                for (int j = i + 1; j < list.Count; j++)
                    if (list[i] + list[j] == 2020)
                        return list[i] * list[j];
            return 0;
        }

        static int Part2(List<int> list)
        {
            for (int i = 0; i < list.Count - 2; i++)
                for (int j = i + 1; j < list.Count - 1; j++)
                    for (int k = j + 1; k < list.Count; k++)
                        if (list[i] + list[j] + list[k] == 2020)
                            return list[i] * list[j] * list[k];
            return 0;
        }

    }
}