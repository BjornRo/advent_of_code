namespace aoc.Solutions;

public partial class Day19
{
    interface IValue { }
    class IntArray(int[][] value) : IValue { public int[][] Value { get; set; } = value; }
    class CharValue(char value) : IValue { public char Value { get; set; } = value; }

    public static void Solve()
    {
        const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
        string[] data = File.ReadAllText("in/d19.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);

        string[] words = data[1].Split(["\r\n", "\n"], SPLITOPT);
        var grammar = GenGrammar(data[0].Split(["\r\n", "\n"], SPLITOPT));
        var grammar2 = GenGrammar(data[0].Split(["\r\n", "\n"], SPLITOPT));
        grammar2[8] = new IntArray([[42], [42, 8]]);
        grammar2[11] = new IntArray([[42, 31], [42, 11, 31]]);
        Console.WriteLine($"Part 1: {words.Count(w => Descender(grammar, 0, w, "", false, out var s) && s == w)}");
        Console.WriteLine($"Part 2: {words.Count(w => Descender(grammar2, 0, w, "", true, out var s) && s == w)}");
    }

    static Dictionary<int, IValue> GenGrammar(string[] data)
    {
        Dictionary<int, IValue> grammar = [];
        foreach (var rule in data.Select(e => e.Split(": ")))
            grammar[int.Parse(rule[0])] = rule[1].Contains('"') ? new CharValue(rule[1].Replace("\"", "")[0]) :
                new IntArray([.. rule[1].Split(" | ").Select(elem => elem.Split(" ").Select(int.Parse).ToArray())]);
        return grammar;
    }

    static bool Descender(
        in Dictionary<int, IValue> grammar, int symbol, string target, string word, bool part2, out string rebuilt
        )
    {
        rebuilt = "";
        if (word.Length >= target.Length) return false;

        var value = grammar[symbol];
        if (value is CharValue res)
        {
            var newWord = word + res.Value;
            if (target.StartsWith(newWord))
            {
                rebuilt = newWord;
                return true;
            }
        }
        else foreach (var arr in ((IntArray)value).Value)
            {
                var conjunct = true;
                string currWord = word;
                foreach (var nextSymbol in arr)
                {
                    if (Descender(grammar, nextSymbol, target, currWord, part2, out var newWord)) currWord = newWord;
                    else
                    {
                        conjunct = false;
                        break;
                    }
                    if (part2 && nextSymbol == 11 && currWord == target)
                    {
                        rebuilt = currWord;
                        return true;
                    }
                }
                if (!conjunct) continue;
                rebuilt = currWord;
                return true;
            }
        return false;
    }
}
