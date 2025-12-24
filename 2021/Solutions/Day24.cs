namespace aoc.Solutions;

public class Day24
{
    public static void Solve()
    {
        // Codegen("in/d24.txt");
        Console.WriteLine($"Part 1: {Runner()}");
        Console.WriteLine($"Part 2: {Runner(true)}");
    }
    static string Runner(bool part2 = false)
    {
        byte[]? Search(byte index, long zValue, Dictionary<(byte, long), byte[]?> memo)
        {
            if (index == 14) return zValue == 0 ? [] : null;
            if (memo.TryGetValue((index, zValue), out var mRes)) return mRes;
            byte[]? numbers = null;
            foreach (var i in part2 ? Utils.Range(1, 9, true) : Utils.Range(9, 1, true))
                if (Search((byte)(index + 1), D24(i, index, zValue), memo) is byte[] res)
                {
                    numbers = [(byte)i, .. res];
                    break;
                }
            return memo[(index, zValue)] = numbers;
        }
        return Search(0, 0, []) is byte[] res ? string.Join("", res) : "";
    }
    static void Codegen(string inputFile, string outputFile = "out.txt")
    {
        List<string> compile = [
            "static long D24(long n, int block, long zValue) {",
                "long w = n;",
                "long x = 0;",
                "long y = 0;",
                "long z = zValue;",
            ];

        int w = -1;
        foreach (var i in File.ReadAllLines(inputFile))
        {
            if (i.Contains("inp"))
            {
                w += 1;
                if (w == 0) compile.Add("switch (block) {");
                else compile.Add($"break;");
                compile.Add($"case {w}:");
                continue;
            }
            var res = i.Split(" ");
            if (res[0] == "add" && res[2] == "0") continue;
            if (res[0] == "mul" && res[2] == "1") continue;
            if (res[0] == "div" && res[2] == "1") continue;
            var symbol = res[0] switch
            { "add" => '+', "mul" => '*', "div" => '/', "mod" => '%', "eql" => '=', _ => '0', };
            if (symbol == '%') compile.Add($"{res[1]} = Utils.Mod({res[1]},{res[2]});");
            else if (symbol == '=') compile.Add($"{res[1]} = {res[1]} == {res[2]} ? {1}L : {0}L;");
            else compile.Add($"{res[1]} {symbol}= {res[2]};");
        }
        compile.Add("break; } return z; }");
        File.WriteAllText(outputFile, string.Join("\n", compile));
    }
    static long D24(long n, int block, long zValue) => 0; // Placeholder
}
