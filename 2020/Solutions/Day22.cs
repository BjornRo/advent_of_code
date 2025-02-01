namespace aoc.Solutions;

public partial class Day22
{
    const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
    static (int[], int[]) Parse(in string[] rawDecks)
    {
        List<int[]> players = [];
        foreach (var rawPlayer in rawDecks)
            players.Add([.. rawPlayer
                .Split(["\r\n", "\n"], count: 2, SPLITOPT)[1]
                .Split(["\r\n", "\n"], SPLITOPT)
                .Select(int.Parse)]
                );
        return (players[0], players[1]);
    }

    public static void Solve()
    {
        string[] data = File.ReadAllText("in/d22.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);
        var players = Parse(data);

        Console.WriteLine($"Part 1: {Part1(players)}");
        Console.WriteLine($"Part 2: {Part2(players).Item2}");
    }

    static int Part1(in (int[] p1, int[] p2) players)
    {
        Queue<int> p1 = new([.. players.p1]);
        Queue<int> p2 = new([.. players.p2]);

        while (p1.Count != 0 && p2.Count != 0)
        {
            var play1 = p1.Dequeue();
            var play2 = p2.Dequeue();
            List<(int, Queue<int>)> plays = [(play1, p1), (play2, p2)];
            plays.Sort((a, b) => b.Item1.CompareTo(a.Item1));
            foreach (var c in plays.Select(e => e.Item1)) plays[0].Item2.Enqueue(c);
        }
        return (p1.Count != 0 ? p1 : p2).Reverse().Select((e, i) => e * (i + 1)).Sum();
    }

    static (int, int) Part2(in (int[] p1, int[] p2) players)
    {
        Queue<int> p1 = new([.. players.p1]);
        Queue<int> p2 = new([.. players.p2]);

        HashSet<string> visited = [];
        while (p1.Count != 0 && p2.Count != 0)
        {
            var key = string.Join(",", p1) + "|" + string.Join(",", p2);
            if (visited.Contains(key)) return (1, 0);
            visited.Add(key);

            var play1 = p1.Dequeue();
            var play2 = p2.Dequeue();

            int[] plays;
            Queue<int> roundWinner;
            if (play1 <= p1.Count && play2 <= p2.Count)
                if (Part2((p1.ToArray()[0..play1], p2.ToArray()[0..play2])).Item1 == 1)
                    (plays, roundWinner) = ([play1, play2], p1);
                else (plays, roundWinner) = ([play2, play1], p2);
            else
            {
                if (play1 > play2) (plays, roundWinner) = ([play1, play2], p1);
                else (plays, roundWinner) = ([play2, play1], p2);
            }
            foreach (var c in plays) roundWinner.Enqueue(c);
        }
        var (winnerID, winner) = p1.Count != 0 ? (1, p1) : (2, p2);
        return (winnerID, winner.Reverse().Select((e, i) => e * (i + 1)).Sum());
    }
}
