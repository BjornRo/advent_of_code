namespace aoc.Solutions
{
    public class Day02
    {
        enum Dir { Forward, Up, Down }
        readonly struct Row
        {
            public Row(string data)
            {
                var s = data.Split(" ");
                Dir = s[0] switch
                {
                    "forward" => Dir.Forward,
                    "down" => Dir.Down,
                    "up" => Dir.Up,
                    _ => throw new NotImplementedException(),
                };
                Value = int.Parse(s[1]);
            }
            public Dir Dir { get; }
            public int Value { get; }

        }
        public static void Solve()
        {
            var data = File.ReadAllLines("in/d02.txt").Select(x => new Row(x)).ToArray();

            Console.WriteLine($"Part 1: {Part1(data)}");
            Console.WriteLine($"Part 2: {Part2(data)}");
        }

        static int Part1(IEnumerable<Row> list)
        {
            int horizontal = 0;
            int depth = 0;
            foreach (var row in list)
                switch (row.Dir)
                {
                    case Dir.Forward:
                        horizontal += row.Value;
                        break;
                    case Dir.Down:
                        depth += row.Value;
                        break;
                    case Dir.Up:
                        depth -= row.Value;
                        break;
                }
            return horizontal * depth;
        }
        static int Part2(IEnumerable<Row> list)
        {
            int horizontal = 0;
            int depth = 0;
            int aim = 0;
            foreach (var row in list)
                switch (row.Dir)
                {
                    case Dir.Forward:
                        horizontal += row.Value;
                        depth += row.Value * aim;
                        break;
                    case Dir.Down:
                        aim += row.Value;
                        break;
                    case Dir.Up:
                        aim -= row.Value;
                        break;
                }
            checked { return horizontal * depth; }
        }
    }
}