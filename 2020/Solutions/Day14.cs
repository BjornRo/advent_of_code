namespace aoc.Solutions;

public class Day14
{
    public static void Solve()
    {
        string[] dataMasking = File.ReadAllLines("in/d14.txt");

        Console.WriteLine($"Part 1: {Part1(dataMasking)}");
        Console.WriteLine($"Part 2: {Part2(dataMasking)}");
    }

    static ulong Part1(in string[] dataMasking)
    {
        Dictionary<ulong, ulong> memory = [];

        ulong maskSet = 0;
        ulong maskUnset = long.MaxValue;
        foreach (var line in dataMasking)
        {
            var maskMem = line.Split(" = ");
            if (maskMem[0].StartsWith("mask"))
            {
                maskSet = 0;
                maskUnset = ulong.MaxValue;
                var revMask = maskMem[1].Reverse().ToArray();
                for (int i = 0; i < 36; i++)
                {
                    if (revMask[i] == '1') maskSet |= 1UL << i;
                    else if (revMask[i] == '0') maskUnset ^= 1UL << i;
                }
            }
            else
            {
                var value = ulong.Parse(maskMem[1]);
                value |= maskSet;
                value &= maskUnset;
                var addr = ulong.Parse(new string([.. maskMem[0].Where(char.IsDigit)]));
                memory[addr] = value;
            }
        }
        return memory.Values.Aggregate((acc, value) => acc + value);
    }

    static void ApplyMask(in char[] mask, in int idx, in ulong addr, in ulong val, Dictionary<ulong, ulong> mem)
    {
        if (mask.Length == idx)
        {
            mem[addr] = val;
            return;
        }

        var c = mask[idx];
        var shift = 1UL << idx;
        if (c == 'X')
        {
            ApplyMask(mask, idx + 1, addr | shift, val, mem);
            ApplyMask(mask, idx + 1, addr & ~shift, val, mem);
        }
        else
        {
            var new_addr = c == '1' ? addr | shift : addr;
            ApplyMask(mask, idx + 1, new_addr, val, mem);
        }
    }

    static ulong Part2(in string[] dataMasking)
    {
        Dictionary<ulong, ulong> memory = [];
        char[] mask = [];
        foreach (var line in dataMasking)
        {
            var maskMem = line.Split(" = ");
            if (maskMem[0].StartsWith("mask")) mask = [.. maskMem[1].Reverse()];
            else
            {
                var address = ulong.Parse(new string([.. maskMem[0].Where(char.IsDigit)]));
                ApplyMask(mask, 0, address, ulong.Parse(maskMem[1]), memory);
            }
        }
        return memory.Values.Aggregate((acc, value) => acc + value);
    }
}
