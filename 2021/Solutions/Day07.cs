namespace aoc.Solutions;

public class Day07
{
    public static void Solve()
    {
        string[] bagData = File.ReadAllLines("in/d07.txt");

        Dictionary<string, Dictionary<string, int>> bagRules = [];
        foreach (var rawRules in Array.ConvertAll(bagData, s => s.Split(" bags contain ")))
        {
            string rest = rawRules[1][..^1];
            Dictionary<string, int> neighbors = [];
            if (!rest.StartsWith("no"))
                foreach (var neighbor in rest.Split(", "))
                {
                    int num = int.Parse(neighbor[..1]);
                    neighbors[num == 1 ? neighbor[2..^4] : neighbor[2..^5]] = num;
                }
            bagRules[rawRules[0]] = neighbors;
        }

        Console.WriteLine($"Part 1: {bagRules.Keys.Select(bag => CanHoldBag(bagRules, bag) ? 1 : 0).Sum()}");
        Console.WriteLine($"Part 2: {BagCounter(bagRules, "shiny gold") - 1}");
    }

    static bool CanHoldBag(in Dictionary<string, Dictionary<string, int>> bagRules, string bag)
    {
        foreach (var neighbor in bagRules[bag])
            if (neighbor.Key.Equals("shiny gold")
                || CanHoldBag(bagRules, neighbor.Key)) return true;
        return false;
    }

    static int BagCounter(in Dictionary<string, Dictionary<string, int>> bagRules, string bag)
    {
        var total = 1;
        foreach (var neighbor in bagRules[bag])
            total += neighbor.Value * BagCounter(bagRules, neighbor.Key);
        return total;
    }
}
