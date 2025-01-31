namespace aoc.Solutions;

public partial class Day22
{
    static void Print(object? s)
    {
        Console.WriteLine(s);
    }
    static void Print()
    {
        Console.WriteLine();
    }
    public static void Solve()
    {
        string[] data = File.ReadAllLines("in/d22t.txt");

        var (p1, p2) = Solver(data);
        Console.WriteLine($"Part 1: {p1}");
        // Console.WriteLine($"Part 2: {p2}");
    }

    static (int, string) Solver(string[] data)
    {

        return (
            1,
            ""
        );
    }
}
