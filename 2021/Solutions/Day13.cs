using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day13
{
    enum Dir { Row, Col }
    readonly struct Fold
    {
        public Fold(string s)
        {
            var x = s.Split("=");
            Axis = x[0] == "y" ? Dir.Row : Dir.Col;
            Value = int.Parse(x[1]);
        }
        public Dir Axis { get; }
        public int Value { get; }
    }
    record Dot(int Row, int Col);
    public static void Solve()
    {
        string[] lines = File.ReadAllText("in/d13.txt").TrimEnd().Replace("\r\n", "\n").Split("\n\n");

        var map = lines[0]
            .Split("\n")
            .Select(r => r.Split(",").Select(int.Parse).ToArray())
            .Select(x => new Dot(x[1], x[0]))
            .ToImmutableArray();
        var folds = lines[1].Split("\n").Select(r => new Fold(r.Split(" ")[^1])).ToArray();

        Console.WriteLine($"Part 1: {Part1([.. map], folds[0]).Count}");
        Console.WriteLine($"Part 2:");
        PM(Part2([.. map], folds));
    }
    static HashSet<Dot> Part1(HashSet<Dot> paper, Fold fold) => [.. paper.Select(dot =>
    {
        bool isRow = fold.Axis == Dir.Row;
        int result = (isRow ? dot.Row : dot.Col) - fold.Value;
        if (0 > result) return dot;
        result *= 2;
        return isRow ? new Dot(dot.Row - result, dot.Col) : new Dot(dot.Row, dot.Col - result);
    })];
    static HashSet<Dot> Part2(HashSet<Dot> paper, Fold[] folds) => folds.Aggregate(paper, Part1);
    static void PM(HashSet<Dot> paper)
    {
        var maxRow = paper.Max(x => x.Row) + 1;
        var maxCol = paper.Max(x => x.Col) + 1;
        var matrix = new char[maxRow][];
        for (int i = 0; i < maxRow; i++) matrix[i] = [.. Enumerable.Repeat(' ', maxCol)];
        foreach (var dot in paper) matrix[dot.Row][dot.Col] = '#';
        foreach (var line in matrix) Console.WriteLine(string.Join("", line));
        Console.WriteLine();
    }

}
