namespace aoc.Solutions;

public partial class Day21
{
    public static void Solve()
    {
        string[] data = File.ReadAllLines("in/d21.txt");

        var (p1, p2) = Solver(data);
        Console.WriteLine($"Part 1: {p1}");
        Console.WriteLine($"Part 2: {p2}");
    }

    static (int, string) Solver(string[] data)
    {
        Dictionary<string, int> counts = [];
        Dictionary<string, HashSet<string>> allergensIngredients = [];
        HashSet<string> allIngredients = [];

        foreach (var row in data)
        {
            var ingCont = row.Split(" (contains ");
            string[] ingredients = ingCont[0].Split(" ");
            string[] allergens = ingCont[1][0..^1].Split(", ");

            foreach (var ingredient in ingredients)
            {
                allIngredients.Add(ingredient);
                if (counts.TryGetValue(ingredient, out var value)) counts[ingredient] = value + 1;
                else counts[ingredient] = 1;
            }

            foreach (var allergen in allergens)
                if (allergensIngredients.TryGetValue(allergen, out var possible)) possible.IntersectWith(ingredients);
                else allergensIngredients[allergen] = [.. ingredients];
        }

        while (allergensIngredients.Any(e => e.Value.Count != 1))
            foreach (var kv in allergensIngredients)
                if (kv.Value.Count == 1)
                    foreach (var value in allergensIngredients.Values)
                        if (value.Count != 1) value.Remove(kv.Value.First());

        List<(string, string)> dangerousList = [];
        foreach (var kv in allergensIngredients)
        {
            var item = kv.Value.First();
            dangerousList.Add((kv.Key, item));
            allIngredients.Remove(item);
        }
        dangerousList.Sort();
        return (
            allIngredients.Aggregate(0, (acc, item) => acc + counts[item]),
            string.Join(",", dangerousList.Select(e => e.Item2))
        );
    }
}
