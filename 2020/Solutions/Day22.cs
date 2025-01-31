namespace aoc.Solutions;

public partial class Day22
{
    const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
    static void Print(object? s)
    {
        Console.WriteLine(s);
    }
    static void Print()
    {
        Console.WriteLine();
    }

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

        // var p1 = Part1(players);
        var p2 = Part2(players);
        // Console.WriteLine($"Part 1: {p1}");
        Console.WriteLine($"Part 2: {p2}");
    }

    static int Part2(in (int[] p1, int[] p2) players)
    {
        Queue<int> p1 = new([.. players.p1]);
        Queue<int> p2 = new([.. players.p2]);

        while (p1.Count != 0 && p2.Count != 0)
        {
            var play1 = p1.Dequeue();
            var play2 = p2.Dequeue();
            List<int> plays = [play1, play2];
            var roundWinner = plays[0] > plays[1] ? p1 : p2;

            plays.Sort((a, b) => b.CompareTo(a));
            foreach (var c in plays) roundWinner.Enqueue(c);
        }
        var winner = p1.Count != 0 ? p1 : p2;
        return winner.Reverse().Select((e, i) => e * (i + 1)).Sum();
    }

    static int Part1(in (int[] p1, int[] p2) players)
    {
        Queue<int> p1 = new([.. players.p1]);
        Queue<int> p2 = new([.. players.p2]);

        while (p1.Count != 0 && p2.Count != 0)
        {
            var play1 = p1.Dequeue();
            var play2 = p2.Dequeue();
            List<int> plays = [play1, play2];
            var roundWinner = plays[0] > plays[1] ? p1 : p2;

            plays.Sort((a, b) => b.CompareTo(a));
            foreach (var c in plays) roundWinner.Enqueue(c);
        }
        var winner = p1.Count != 0 ? p1 : p2;
        return winner.Reverse().Select((e, i) => e * (i + 1)).Sum();
    }
}
