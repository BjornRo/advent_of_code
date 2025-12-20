using System.Collections.Immutable;
using System.Numerics;

namespace aoc.Solutions;

public static class Utils
{
    public static T[][][] DeepCopy<T>(T[][][] source) where T : struct
    {
        var copy = new T[source.Length][][];
        for (int i = 0; i < source.Length; i++) copy[i] = DeepCopy(source[i]);
        return copy;
    }
    public static T[][] DeepCopy<T>(T[][] source) where T : struct
    {
        var copy = new T[source.Length][];
        for (int i = 0; i < source.Length; i++) copy[i] = Copy(source[i]);
        return copy;
    }
    public static T[] Copy<T>(T[] source) where T : struct
    {
        var copy = new T[source.Length];
        Array.Copy(source, copy, source.Length);
        return copy;
    }
    public static string FmtA<T>(IEnumerable<T> array) => $"[{string.Join(", ", array)}]";
    public static string FmtV<T>(Vector<T> v) where T : struct
    {
        T[] arr = new T[Vector<T>.Count];
        v.CopyTo(arr);
        return $"[{string.Join(", ", arr)}]";
    }
    public static void PrintA<T>(IEnumerable<T> array) => Console.WriteLine(FmtA(array));
    public static void PrintM<T>(IEnumerable<IEnumerable<T>> mat)
    { foreach (var arr in mat) Console.WriteLine(FmtA(arr)); }
    public static void PrintM<T>(IEnumerable<ImmutableArray<T>> mat)
    { foreach (var arr in mat) Console.WriteLine(FmtA(arr)); }
    public static IEnumerable<(int, int)> Cross3(int maxRow, int maxCol, int row, int col)
    {
        foreach (var (dr, dc) in new[] { (row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1) })
            if (0 <= dr && dr < maxRow && 0 <= dc && dc < maxCol)
                yield return (dr, dc);
    }
    public static IEnumerable<(int, int)> Kernel3(int maxRow, int maxCol, int row, int col)
    {
        for (int i = -1; i < 2; i++)
            for (int j = -1; j < 2; j++)
                if (i != 0 || j != 0)
                {
                    var (dr, dc) = (row + i, col + j);
                    if (0 <= dr && dr < maxRow && 0 <= dc && dc < maxCol)
                        yield return (dr, dc);
                }
    }
    public static int Manhattan((int x, int y) a, (int x, int y) b) => Math.Abs(a.x - b.x) + Math.Abs(a.y - b.y);
}