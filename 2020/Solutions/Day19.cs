namespace aoc.Solutions;

interface IMyValue { }

class IntArray(int[][] value) : IMyValue
{
    public int[][] Value { get; set; } = value;
}

class CharValue(char value) : IMyValue
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
        Console.WriteLine($"Part 1: {Part1(grammar, words)}");
        // Console.WriteLine($"Part 2: {data.Aggregate(0L, (acc, str) => acc + Eval(str, false))}");
    }

    static Dictionary<int, IMyValue> GenGrammar(string[] data)
    {
        Dictionary<int, IMyValue> grammar = [];

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

    // 46 23 not right
    static bool Descender(
        in Dictionary<int, IMyValue> grammar, int symbol, string targetWord, string word, out string rebuiltWord
        )
    {
        rebuiltWord = "";
        if (word.Length > targetWord.Length) return false;

        var value = grammar[symbol];
        if (value is CharValue res)
        {
            var newWord = word + res.Value;
            if (targetWord.StartsWith(newWord))
            {
                rebuiltWord = newWord;
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
                if (Descender(grammar, arr[i], targetWord, currentWord, out string newWord)) currentWord = newWord;
                else
                {
                    conjunct = false;
                    break;
                }
            }
            if (conjunct)
            {
                rebuiltWord = currentWord;
                return true;
            }
        }
        return false;
    }

    static int Part1(in Dictionary<int, IMyValue> grammar, string[] words)
    {
        int total = 0;
        foreach (var word in words)
        {
            if (Descender(grammar, 0, word, "", out string rebuilt))
            {
                Console.WriteLine(word);
                Console.WriteLine(rebuilt);
                Console.WriteLine();
                if (rebuilt == word) total += 1;
            }
            // break;
        }


        return total;
    }
}
