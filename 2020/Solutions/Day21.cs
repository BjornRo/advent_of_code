using System.Text.Unicode;

namespace aoc.Solutions;

public partial class Day21
{
    struct Ingredient(in string name, in string[] contains)
    {
        public HashSet<string> Contains = [.. contains];
        public readonly string Name = name;
    }
    public static void Solve()
    {
        string[] data = File.ReadAllLines("in/d21t.txt");

        Console.WriteLine($"Part 1: {Part1(data)}");
        // Console.WriteLine($"Part 2: {2}");
    }

    static int Part1(string[] data)
    {
        Dictionary<string, HashSet<string>> ingredients = [];
        foreach (var row in data)
        {
            var ingCont = row.Split(" (contains ");
            HashSet<string> contains = [.. ingCont[1][0..^1].Split(", ")];
            foreach (var ingredient in ingCont[0].Split(" "))
            {
                if (ingredients.TryGetValue(ingredient, out var cont))
                {
                    cont.IntersectWith(contains);
                }
                else ingredients[ingredient] = [.. contains];
            }
        }
        foreach (var item in ingredients)
        {
            Console.WriteLine($"{item.Key} {item.Value.Count}");
        }
        return 1;
    }

}
