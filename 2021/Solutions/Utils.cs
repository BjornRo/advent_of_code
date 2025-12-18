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
    public static string FmtA<T>(T[] array) => $"[{string.Join(", ", array)}]";
    public static string FmtV<T>(Vector<T> v) where T : struct
    {
        T[] arr = new T[Vector<T>.Count];
        v.CopyTo(arr);
        return $"[{string.Join(", ", arr)}]";
    }
    public static void PrintA<T>(T[] array) => Console.WriteLine(FmtA(array));
}