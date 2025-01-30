using System.Text.RegularExpressions;

namespace aoc.Solutions;

public partial class Day18
{
    public static void Solve()
    {
        string[] data = File.ReadAllLines("in/d18.txt");

        Console.WriteLine($"Part 1: {data.Aggregate(0L, (acc, str) => acc + Eval(str, true))}");
        Console.WriteLine($"Part 2: {data.Aggregate(0L, (acc, str) => acc + Eval(str, false))}");
    }

    static long Eval(string expr, bool ignorePrecedence)
    {
        int GetPrecedence(string op)
        {
            if (ignorePrecedence) return 0;
            if (op == "*") return 1;
            if (op == "+") return 2;
            return 0;
        }
        string[] tokens = [.. MyRegex().Matches(expr).Select(e => e.Value)];

        Stack<string> stack = [];
        List<string> output = [];

        foreach (var token in tokens)
        {
            if (char.IsDigit(token[0])) output.Add(token);
            else if (token == "(") stack.Push(token);
            else if (token == ")")
            {
                while (stack.Count > 0 && stack.Peek() != "(") output.Add(stack.Pop());
                stack.Pop();
            }
            else
            {
                while (stack.Count > 0 && stack.Peek() != "("
                    && GetPrecedence(stack.Peek()) >= GetPrecedence(token))
                    output.Add(stack.Pop());
                stack.Push(token);
            }
        }
        while (stack.Count > 0) output.Add(stack.Pop());

        Stack<long> evalStack = [];
        foreach (var token in output)
            if (char.IsDigit(token[0])) evalStack.Push(long.Parse(token));
            else
            {
                var b = evalStack.Pop();
                var a = evalStack.Pop();
                evalStack.Push(token == "+" ? a + b : a * b);
            }
        return evalStack.Pop();
    }

    [GeneratedRegex(@"\d+|\+|\*|\(|\)")]
    private static partial Regex MyRegex();
}
