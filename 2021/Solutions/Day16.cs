namespace aoc.Solutions;

public class Day16
{
    static byte[] Char2Byte(char c)
    {
        static byte Shift(int v, int shift) => (byte)((v >> shift) & 1);
        var v = c switch
        {
            >= '0' and <= '9' => c - '0',
            _ => c - 'A' + 10,
        };
        return [Shift(v, 3), Shift(v, 2), Shift(v, 1), Shift(v, 0)];
    }
    public static void Solve()
    {
        var data = File.ReadAllText("in/d16.txt").Trim().SelectMany(Char2Byte).ToArray();

        Console.WriteLine($"Part 1: {Part1(data).Value}");
        Console.WriteLine($"Part 2: {Part2(data).Value}");
    }
    static int Arr2Int(IEnumerable<byte> arr) => arr.Aggregate(0, (agg, v) => (agg << 1) | (v & 1));
    static (int Value, byte[] Remaining) Part1(byte[] data)
    {
        var ver = Arr2Int(data[..3]);
        if (Arr2Int(data[3..6]) == 4)
        {
            data = data[6..];
            while (data[0] != 0) data = data[5..];
            return (ver, data[5..]);
        }

        if (Arr2Int(data[6..7]) == 0)
        {
            var packetLen = Arr2Int(data[7..22]);
            var packetData = data[22..(22 + packetLen)];
            while (packetData.Length != 0)
            {
                (var value, packetData) = Part1(packetData);
                ver += value;
            }
            return (ver, data[(22 + packetLen)..]);
        }

        var nPackets = Arr2Int(data[7..18]);
        data = data[18..];
        foreach (var _ in Enumerable.Range(0, nPackets))
        {
            (var value, data) = Part1(data);
            ver += value;
        }
        return (ver, data);
    }
    static (long Value, byte[] Remaining) Part2(byte[] data)
    {
        var op = Arr2Int(data[3..6]);
        if (op == 4)
        {
            long value = 0;
            data = data[6..];
            while (true)
            {
                foreach (var b in data[1..5]) value = (value << 1) | b;
                if (data[0] == 0) break;
                data = data[5..];
            }
            return (value, data[5..]);
        }
        List<long> packetValues = [];
        if (Arr2Int(data[6..7]) == 0)
        {
            var packetLen = Arr2Int(data[7..22]);
            var packetData = data[22..(22 + packetLen)];
            while (packetData.Length != 0)
            {
                (var value, packetData) = Part2(packetData);
                packetValues.Add(value);
            }
            data = data[(22 + packetLen)..];
        }
        else
        {
            (var nPackets, data) = (Arr2Int(data[7..18]), data[18..]);
            foreach (var _ in Enumerable.Range(0, nPackets))
            {
                (var value, data) = Part2(data);
                packetValues.Add(value);
            }
        }
        var res = op switch
        {
            0 => packetValues.Sum(),
            1 => packetValues.Aggregate(1L, (prod, v) => prod * v),
            2 => packetValues.Min(),
            3 => packetValues.Max(),
            5 => packetValues[0] > packetValues[1] ? 1 : 0,
            6 => packetValues[0] < packetValues[1] ? 1 : 0,
            7 => packetValues[0] == packetValues[1] ? 1 : 0,
            _ => throw new Exception("not here"),
        };
        return (res, data);
    }
}