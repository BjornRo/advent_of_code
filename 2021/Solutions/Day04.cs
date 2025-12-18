namespace aoc.Solutions
{
    public class Day04
    {
        public static void Solve()
        {
            var data = File.ReadAllText("in/d04.txt")
                .TrimEnd()
                .Replace("\r\n", "\n")
                .Split("\n\n", 2);

            int[] drawn = [.. data[0].Split(",").Select(int.Parse)];
            int[][][] boards = [.. data[1]
                .Split("\n\n")
                .Select(x => x
                    .Split("\n")
                    .Select(y => y.Split(" ", StringSplitOptions.RemoveEmptyEntries).Select(int.Parse).ToArray())
                    .ToArray())];

            Console.WriteLine($"Part 1: {Part1(drawn, boards)}");
            Console.WriteLine($"Part 2: {Part2(drawn, boards)}");
        }
        static int[]? Won(IEnumerable<int[][]> boards)
        {
            var won = new List<int>();
            foreach (var (i, b) in boards.Select((x, i) => (i, x)))
            {
                var row = b.Any(row => row.All(x => x == -1));
                var col = Enumerable.Range(0, b[0].Length)
                    .Any(i => Enumerable.Range(0, b.Length).All(j => b[j][i] == -1));
                if (row || col) won.Add(i);
            }
            return won.Count == 0 ? null : [.. won.OrderBy(x => -x)];
        }
        static int Count(int[][] board) => board.Sum(r => r.Where(x => x != -1).Sum());
        static int[]? Round(int draw, IEnumerable<int[][]> boards)
        {
            foreach (var board in boards)
                foreach (var row in board)
                    for (int i = 0; i < row.Length; i++)
                        if (row[i] == draw) row[i] = -1;
            return Won(boards);
        }
        static int Part1(int[] drawn, int[][][] _boards)
        {
            var boards = Utils.DeepCopy(_boards);
            var res = drawn.Select(r => (r, Round(r, boards))).First(x => x.Item2 != null);
            return res.r * Count(boards[res.Item2![^1]]);
        }
        static int Part2(int[] drawn, int[][][] _boards)
        {
            var boards = Utils.DeepCopy(_boards).ToList();
            foreach (var draw in drawn)
                if (Round(draw, boards) is int[] value)
                    foreach (var i in value)
                        if (boards.Count == 1) return draw * Count(boards[i]);
                        else boards.RemoveAt(i);
            return -1;
        }
    }
}