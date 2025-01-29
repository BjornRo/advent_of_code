
namespace aoc.Solutions
{

    readonly struct Coords(int min, int max, char symbol, string pwd)
    {
        public int Min { get; } = min;
        public int Max { get; } = max;
        public char Symbol { get; } = symbol;
        public string Password { get; } = pwd;
    }

    public class Day02
    {
        public static void Solve()
        {
            string[] lines = File.ReadAllLines("in/d02.txt");

            List<Coords> list = [];
            foreach (var line in lines)
            {
                string[] split_line = line.Split(" ");
                var values = split_line[0].Split('-').Select(int.Parse).ToArray();
                list.Add(new Coords(values[0], values[1], split_line[1][0], split_line[2]));
            }

            Console.WriteLine($"Part 1: {Part1(list)}");
            Console.WriteLine($"Part 2: {Part2(list)}");
        }

        static int Part1(List<Coords> list)
        {
            int total = 0;

            foreach (var pwd in list)
            {
                int num = pwd.Password.Count(c => c == pwd.Symbol);
                if (pwd.Min <= num && num <= pwd.Max) total += 1;
            }
            return total;
        }

        static int Part2(List<Coords> list)
        {
            int total = 0;

            foreach (var pwd in list)
            {
                string pass = pwd.Password;
                if (pass[pwd.Min - 1] == pwd.Symbol != (pass[pwd.Max - 1] == pwd.Symbol))
                    total += 1;
            }
            return total;
        }
    }
}