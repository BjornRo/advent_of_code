using System.Numerics;


namespace aoc.Solutions
{
    public class Day01
    {
        enum Label
        {
            L,
            R,
        }
        record Row(Label Label, int Value);

        static int Mod(int a, int b) => ((a % b) + b) % b;


        public static void Solve()
        {
            string[] lines = File.ReadAllLines("in/d01.txt");

            List<Row> list = [];
            foreach (var line in lines)
            {
                if (int.TryParse(line.Skip(1).ToArray(), out int num))
                {
                    list.Add(new(line[0] == 'L' ? Label.L : Label.R, num));

                }
            }
            Console.WriteLine($"Part 1: {Part1(list)}");
            Console.WriteLine($"Part 2: {Part2(list)}");
        }

        static int Part1(in List<Row> list)
        {
            var dial = 50;
            var count = 0;

            foreach (Row r in list)
            {
                switch (r.Label)
                {
                    case Label.L:
                        dial -= r.Value;
                        break;
                    case Label.R:
                        dial += r.Value;
                        break;
                }
                dial %= 100;
                if (dial == 0)
                {
                    count += 1;
                }
            }
            return count;
        }
        static int Part2(in List<Row> list)
        {
            double unixTime = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
            var dial = 50;
            var count = 0;

            foreach (Row r in list)
            {
                Func<int, int> func = r.Label == Label.L ? (x => x - 1) : (x => x + 1);
                for (int i = 0; i < r.Value; i++)
                {
                    dial = Mod(func(dial), 100);
                    if (dial == 0)
                    {
                        count += 1;
                    }
                }
            }
            Console.WriteLine(DateTimeOffset.UtcNow.ToUnixTimeMilliseconds() - unixTime);
            return count;
        }

        static int Part2x(in List<Row> list)
        {
            var dial = 50;
            var count = 0;

            foreach (Row r in list)
            {
                var sign = Math.Sign(dial);
                switch (r.Label)
                {
                    case Label.L:
                        dial -= r.Value;
                        break;
                    case Label.R:
                        dial += r.Value;
                        break;
                }

                if ((sign != 0 && Math.Sign(dial) != sign) || dial >= 100 || dial <= -100 || r.Value >= 100)
                {
                    int value = r.Value / 100;
                    value = Math.Max(1, value);
                    count += value;
                    var fac = dial % value;
                    if (fac != 1 && fac != 0)
                    {
                        count += 1;
                    }
                }

                // Console.WriteLine("D {0}, C {1}", dial, count);
                dial = Mod(dial, 100);
                // 2162, 2557, 2684 too low
                // Console.WriteLine(dial);

            }
            return count;
        }

    }
}

