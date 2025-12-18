using System.Numerics;

namespace aoc.Solutions;

public static class Utils
{
    public static T[][] DeepCopy<T>(T[][] source) where T : struct
    {
        var copy = new T[source.Length][];
        for (int i = 0; i < source.Length; i++)
        {
            copy[i] = new T[source[i].Length];
            Array.Copy(source[i], copy[i], source[i].Length);
        }
        return copy;
    }
    public static string FmtA<T>(T[] array) => $"[{string.Join(", ", array)}]";
    public static string FmtV<T>(Vector<T> v) where T : struct
    {
        T[] arr = new T[Vector<T>.Count];
        v.CopyTo(arr);
        return $"[{string.Join(", ", arr)}]";
    }
    public static void PrintA<T>(T[] array) => Console.WriteLine(FmtA(array));
}