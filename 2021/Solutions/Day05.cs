namespace aoc.Solutions
{
    public class Day05
    {
        record Point(int Row, int Col);
        readonly struct Line
        {
            public Line(string raw)
            {
                var res = raw.Replace(" -> ", ",").Split(",").Select(int.Parse).ToArray();
                A = new Point(res[0], res[1]);
                B = new Point(res[2], res[3]);
            }
            public Point A { get; }
            public Point B { get; }
            public HashSet<Point> Draw()
            {
                var points = new HashSet<Point>();
                var (x0, y0) = A;
                var (x1, y1) = B;

                int dx = Math.Abs(x1 - x0);
                int dy = -Math.Abs(y1 - y0);
                int sx = x0 < x1 ? 1 : -1;
                int sy = y0 < y1 ? 1 : -1;
                int err = dx + dy;

                while (true)
                {
                    points.Add(new Point(y0, x0));
                    if (x0 == x1 && y0 == y1) break;
                    int e2 = 2 * err;
                    if (e2 >= dy)
                    {
                        err += dy;
                        x0 += sx;
                    }
                    if (e2 <= dx)
                    {
                        err += dx;
                        y0 += sy;
                    }
                }
                return points;
            }
        }
        public static void Solve()
        {
            var (p1, p2) = Solver([.. File.ReadAllLines("in/d05.txt").Select(x => new Line(x))]);
            Console.WriteLine($"Part 1: {p1}");
            Console.WriteLine($"Part 2: {p2}");
        }
        static (int, int) Solver(Line[] lines)
        {
            Dictionary<Point, int> p1 = [];
            Dictionary<Point, int> p2 = [];
            foreach (var (i, line) in lines.Select((x, i) => (i, x)))
                foreach (var p in line.Draw())
                {
                    p2[p] = p2.TryGetValue(p, out var value) ? value + 1 : 1;
                    if (line.A.Row == line.B.Row || line.A.Col == line.B.Col)
                        p1[p] = p1.TryGetValue(p, out value) ? value + 1 : 1;
                }
            return (p1.Values.Sum(x => x == 1 ? 0 : 1), p2.Values.Sum(x => x == 1 ? 0 : 1));
        }
    }
}