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
    public static int Manhattan((int x, int y, int z) a, (int x, int y, int z) b) =>
        Math.Abs(a.x - b.x) + Math.Abs(a.y - b.y) + Math.Abs(a.z - b.z);
    public static T InvArithmetic<T>(T t) where T : INumber<T>, IRootFunctions<T> =>
        (T.Sqrt(T.CreateChecked(8) * t + T.One) - T.One) / T.CreateChecked(2);
    public static T Arithmetic<T>(T n) where T : INumber<T> => n * (n + T.One) / T.CreateChecked(2);
    public static (T min, T max) MinMax<T>(T[] numbers) where T : IComparable<T>
    {
        T min = numbers[0], max = numbers[0];
        for (int i = 1; i < numbers.Length; i++)
        {
            if (numbers[i].CompareTo(min) < 0) min = numbers[i];
            if (numbers[i].CompareTo(max) > 0) max = numbers[i];
        }
        return (min, max);
    }
    public static ((T1 min, T1 max), (T2 min, T2 max)) MinMax<T1, T2>((T1, T2)[] values)
    where T1 : IComparable<T1>
    where T2 : IComparable<T2>
    {
        T1 min1 = values[0].Item1, max1 = values[0].Item1;
        T2 min2 = values[0].Item2, max2 = values[0].Item2;

        for (int i = 1; i < values.Length; i++)
        {
            var (a, b) = values[i];
            if (a.CompareTo(min1) < 0) min1 = a;
            if (a.CompareTo(max1) > 0) max1 = a;
            if (b.CompareTo(min2) < 0) min2 = b;
            if (b.CompareTo(max2) > 0) max2 = b;
        }
        return ((min1, max1), (min2, max2));
    }
    public static IEnumerable<int> Range(int start, int stop) { for (int i = start; i < stop; i++) yield return i; }
    public static IEnumerable<int> Range(int start, int stop, bool inclusive = true)
    {
        int end = inclusive ? stop : stop - 1;
        for (int i = start; i <= end; i++) yield return i;
    }
    public static IEnumerable<(T a, T b)> DistinctPairs<T>(IEnumerable<T> source)
    {
        T[] list = [.. source];
        for (int i = 0; i < list.Length - 1; i++)
            for (int j = i + 1; j < list.Length; j++)
                yield return (list[i], list[j]);
    }
    public static IEnumerable<(T a, T b)> OrderedPairs<T>(IEnumerable<T> source)
    {
        T[] list = [.. source];
        for (int i = 0; i < list.Length; i++)
            for (int j = 0; j < list.Length; j++)
                if (i != j) yield return (list[i], list[j]);
    }
    public static IEnumerable<(int, T b)> Enumerate<T>(IEnumerable<T> source) => source.Select((x, i) => (i, x));
    public static IEnumerable<(int, T b)> Enumerate<T>(int start, IEnumerable<T> source) => source.Skip(start).Select((x, i) => (i + start, x));
}