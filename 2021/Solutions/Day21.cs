namespace aoc.Solutions;

public class Day21
{
    public static void Solve()
    {
        var startPos = File.ReadAllLines("in/d21.txt").Select(x => x[^1] - '0').ToArray();
        Console.WriteLine($"Part 1: {Part1(startPos[0], startPos[1])}");
        Console.WriteLine($"Part 2: {Part2(startPos[0], startPos[1])}");
    }
    static long Mod(long value) => (value - 1) % 10 + 1;
    static long Part1(long p1Pos, long p2Pos)
    {
        var rolls = 0;
        var value = 0;
        IEnumerable<long> Roll()
        {
            while (true)
            {
                rolls += 1;
                value += 1;
                if (value > 100) value = 1;
                yield return value;
            }
        }
        var rolldice = Roll();
        long p1Score = 0, p2Score = 0;
        while (true)
        {
            p1Pos = Mod(rolldice.Take(3).Sum() + p1Pos);
            p1Score += p1Pos;
            if (p1Score >= 1000) return p2Score * rolls;
            p2Pos = Mod(rolldice.Take(3).Sum() + p2Pos);
            p2Score += p2Pos;
            if (p2Score >= 1000) return p1Score * rolls;
        }
    }
    static long Part2(long p1Pos, long p2Pos)
    {
        IEnumerable<long> Roll() =>
            from i in Enumerable.Range(1, 3)
            from j in Enumerable.Range(1, 3)
            from k in Enumerable.Range(1, 3)
            select (long)(i + j + k);

        Dictionary<(long, long, long, long, bool), (long, long)> memo = [];
        (long, long) Play(long p1Pos, long p2Pos, long p1Score, long p2Score, bool p1Turn)
        {
            if (p1Score >= 21) return (1, 0);
            if (p2Score >= 21) return (0, 1);
            if (memo.TryGetValue((p1Pos, p2Pos, p1Score, p2Score, p1Turn), out var result)) return result;

            long p1Wins = 0, p2Wins = 0;
            foreach (var roll in Roll())
            {
                long p1 = 0, p2 = 0;
                if (p1Turn)
                {
                    var _p1Pos = Mod(roll + p1Pos);
                    (p1, p2) = Play(_p1Pos, p2Pos, p1Score + _p1Pos, p2Score, false);
                }
                else
                {
                    var _p2Pos = Mod(roll + p2Pos);
                    (p1, p2) = Play(p1Pos, _p2Pos, p1Score, p2Score + _p2Pos, true);
                }
                p1Wins += p1;
                p2Wins += p2;
            }
            memo[(p1Pos, p2Pos, p1Score, p2Score, p1Turn)] = (p1Wins, p2Wins);
            return (p1Wins, p2Wins);
        }
        var (a, b) = Play(p1Pos, p2Pos, 0, 0, true);
        return Math.Max(a, b);
    }
}
