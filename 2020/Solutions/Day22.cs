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
        string[] data = File.ReadAllText("in/d22t.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);
        var players = Parse(data);

        var p1 = Solver(players);
        Console.WriteLine($"Part 1: {p1}");
        // Console.WriteLine($"Part 2: {p2}");
    }

    static int Solver((int[], int[]) players)
    {

        return 1;
    }
}
