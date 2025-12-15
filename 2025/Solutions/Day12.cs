using System.Numerics;

namespace aoc.Solutions;

public class Day12
{
    readonly static int Dimension = 3;
    readonly struct ShapeData
    {
        public ShapeData(string row)
        {
            var x = row.Split(": ");
            var left = x[0].Split("x").Select(int.Parse).ToArray();
            Row = left[1];
            Col = left[0];
            Quantity = [.. x[1].Split().Select(int.Parse)];
        }
        public int Row { get; }
        public int Col { get; }
        public int[] Quantity { get; }
    }
    static (int, char[][][]) GenShapes(char[][] shape)
    {
        List<char[][]> newShapes = [shape];
        foreach (var ls in new[] { shape, Flip(shape) })
        {
            var s = ls;
            for (int i = 0; i < 3; i++)
            {
                s = Rotate(s);
                if (!newShapes.Any(ns => ns.Zip(s).All(e => e.First.SequenceEqual(e.Second))))
                    newShapes.Add(s);
            }
        }
        return (shape.Sum(row => row.Count(c => c == '#')), [.. newShapes]);
    }

    public static void Solve()
    {
        string[] data = File.ReadAllText("in/d12.txt").Replace("\r\n", "\n").TrimEnd().Split("\n\n");
        var shapes = data[..^1]
            .Select(
                elem => elem
                    .Split(":\n")[1]
                    .Split("\n")
                    .Select(x => x.ToCharArray().Select(x => x == '.' ? '\0' : x).ToArray())
                    .ToArray())
            .Select(GenShapes).ToArray();
        ShapeData[] shapedata = [.. data[^1].Split("\n").Select(x => new ShapeData(x))];

        Console.WriteLine($"Part 1: {Part1(shapes, shapedata)}");
    }
    static void AddShape(char[][] matrix, char[][] shape, int row, int col)
    {
        for (int i = 0; i < Dimension; i++)
            for (int j = 0; j < Dimension; j++)
                if (shape[i][j] != '\0') matrix[row + i][col + j] = shape[i][j];
    }
    static void RemoveShape(char[][] matrix, char[][] shape, int row, int col)
    {
        for (int i = 0; i < Dimension; i++)
            for (int j = 0; j < Dimension; j++)
                if (shape[i][j] != '\0') matrix[row + i][col + j] = '\0';
    }
    static bool ShapeFits(char[][] matrix, char[][] shape, int row, int col)
    {
        for (int i = 0; i < Dimension; i++)
            for (int j = 0; j < Dimension; j++)
                if (shape[i][j] != '\0' && matrix[row + i][col + j] != '\0') return false;
        return true;
    }
    static long Part1((int, char[][][])[] shapes, ShapeData[] shapedata)
    {
        bool Backtrack(char[][] matrix, int[] quantity, int shapeIndex, int shapeQuant, int row = 0, int col = 0)
        {
            if (shapeIndex >= quantity.Length) return true;
            if (quantity[shapeIndex] <= shapeQuant) return Backtrack(matrix, quantity, shapeIndex + 1, 0);
            for (int i = row; i <= matrix.Length - Dimension; i++)
                for (int j = col; j <= matrix[0].Length - Dimension; j++)
                    foreach (var shape in shapes[shapeIndex].Item2)
                        if (ShapeFits(matrix, shape, i, j))
                        {
                            AddShape(matrix, shape, i, j);
                            if (Backtrack(matrix, quantity, shapeIndex, shapeQuant + 1)) return true;
                            RemoveShape(matrix, shape, i, j);
                        }
            return false;
        }

        var res = shapedata.AsParallel().Sum(data =>
        {
            var size = data.Row * data.Col;
            var required = data.Quantity.Select((x, i) => shapes[i].Item1 * x).Sum();
            if (size < required) return 0;
            char[][] matrix = new char[data.Row][];
            for (int i = 0; i < data.Row; i++) matrix[i] = new char[data.Col];
            return Backtrack(matrix, data.Quantity, 0, 0) ? 1 : 0;
        });

        return res;
    }
    public static char[][] Flip(char[][] matrix)
    {
        int rows = matrix.Length;
        char[][] flip = new char[rows][];
        for (int i = 0; i < rows; i++)
        {
            int cols = matrix[i].Length;
            flip[i] = new char[cols];
            for (int j = 0; j < cols; j++) flip[i][j] = matrix[i][cols - 1 - j];
        }
        return flip;
    }
    public static char[][] Transpose(char[][] matrix)
    {
        int rows = matrix.Length;
        int cols = matrix[0].Length;
        char[][] trans = new char[cols][];
        for (int i = 0; i < cols; i++)
        {
            trans[i] = new char[rows];
            for (int j = 0; j < rows; j++) trans[i][j] = matrix[j][i];
        }
        return trans;
    }
    static char[][] Rotate(char[][] matrix) => Transpose(Flip(matrix));
    static string FmtA(char[] array) => $"[{string.Join(", ", array)}]";
    static string FmtM(char[][] m)
    {
        List<string> f = [];
        foreach (var r in m) f.Add(FmtA([.. r.Select(x => x == '\0' ? ' ' : x)]));
        return string.Join("\n", f);
    }
    static void PrintM(char[][] m) => Console.WriteLine(FmtM(m));
}
