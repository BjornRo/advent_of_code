namespace aoc.Solutions;

interface IValue { }

class IntArray(int[][] value) : IValue
{
    public int[][] Value { get; set; } = value;
}

class CharValue(char value) : IValue
{
    public char Value { get; set; } = value;
}

public partial class Day19
{
    public static void Solve()
    {
        const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
        string[] data = File.ReadAllText("in/d19.txt").Split(["\r\n\r\n", "\n\n"], SPLITOPT);

        string[] words = data[1].Split(["\r\n", "\n"], SPLITOPT);
        var grammar = GenGrammar(data[0].Split(["\r\n", "\n"], SPLITOPT));
        var grammar2 = GenGrammar(data[0].Split(["\r\n", "\n"], SPLITOPT));
        grammar2[8] = new IntArray([[42], [42, 8]]);
        grammar2[11] = new IntArray([[42, 31], [42, 11, 31]]);
        Console.WriteLine(
            $"Part 1: {words.Count(w => Descender(grammar, 0, w, "", false, out string str) && str == w)}"
            );
        Console.WriteLine(
            $"Part 2: {words.Count(w => Descender(grammar2, 0, w, "", true, out string str) && str == w)}"
            );
    }

    static Dictionary<int, IValue> GenGrammar(string[] data)
    {
        Dictionary<int, IValue> grammar = [];

        foreach (var rawRule in data.Select(e => e.Split(": ")))
        {
            var left = int.Parse(rawRule[0]);
            if (rawRule[1].Contains('"'))
            {
                grammar[left] = new CharValue(rawRule[1].Replace("\"", "")[0]);
                continue;
            }
            var right = rawRule[1].Split(" | ");
            grammar[left] = new IntArray([.. right.Select(elem => elem.Split(" ").Select(int.Parse).ToArray())]);
        }
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
            return false;
        }

        foreach (var arr in ((IntArray)value).Value)
        {
            var conjunct = true;
            string currentWord = word;
            for (int i = 0; i < arr.Length; i++)
            {
                if (Descender(grammar, arr[i], target, currentWord, part2, out string newWord)) currentWord = newWord;
                else
                {
                    conjunct = false;
                    break;
                }
                if (part2 && arr[i] == 11 && currentWord == target)
                {
                    rebuilt = currentWord;
                    return true;
                }
            }
            if (!conjunct) continue;
            rebuilt = currentWord;
            return true;
        }
        return false;
    }
}
