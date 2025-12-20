using System.Text.RegularExpressions;

namespace aoc.Solutions;
#pragma warning disable SYSLIB1045
public class Day17
{
    readonly struct Area(int[] numbers)
    {
        public readonly int RowMin = numbers[^1];
        public readonly int RowMax = numbers[^2];
        public readonly int ColMin = numbers[0];
        public readonly int ColMax = numbers[1];
        public readonly bool Within(int row, int col) =>
            RowMin <= row && row <= RowMax && ColMin <= col && col <= ColMax;
        public readonly bool Overshot(int row, int col) =>
            row > RowMax || col > ColMax;
    }

    public static void Solve()
    {
        var area = new Area([.. new Regex(@"\d+")
            .Matches(File.ReadAllText("in/d17.txt").Trim())
            .Select(m => int.Parse(m.Value))]);

        Console.WriteLine($"Part 1: {Utils.Arithmetic(area.RowMax - 1)}");
        Console.WriteLine($"Part 2: {Part2(area)}");
    }
    static int Part2(Area area)
    {
        static bool Cannon(Area area, int deltaRow, int deltaCol)
        {
            int row = 0, col = 0;
            while (!area.Overshot(row, col))
            {
                row += -deltaRow;
                col += deltaCol;
                if (area.Within(row, col)) return true;
                deltaRow -= 1;
                if (deltaCol != 0) deltaCol -= 1;
            }
            return false;
        }
        HashSet<(int, int)> map = [];
        for (int row = -area.RowMax; row < area.RowMax; row++)
            for (int col = (int)Utils.InvArithmetic((double)area.ColMin); col <= area.ColMax; col++)
                if (Cannon(area, row, col)) map.Add((row, col));
        return map.Count;
    }
}
