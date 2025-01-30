namespace aoc.Solutions;

public class Day17
{
    public static void Solve()
    {
        string data = File.ReadAllText("in/d16.txt");

        var (clsRanges, ticket, nearTickets) = Parse(data);
        var (p1_result, validTickets) = Part1(clsRanges, nearTickets);

        Console.WriteLine($"Part 1: {p1_result}");
        Console.WriteLine($"Part 2: {Part2(clsRanges, ticket, validTickets)}");
    }

    static (Dictionary<string, (int, int)[]>, ulong[], int[][]) Parse(string data)
    {
        Dictionary<string, (int, int)[]> clsRanges = [];
        ulong[] ticket;
        int[][] nearTickets;

        var SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
        string[] splitData = data.Split(["\r\n\r\n", "\n\n"], SPLITOPT);

        foreach (var rawClassRange in splitData[0].Split(["\r\n", "\n"], SPLITOPT))
        {
            var keyVals = rawClassRange.Split(": ");
            (int, int)[] ranges = new (int, int)[2];
            foreach (var (rawRange, i) in keyVals[1].Split(" or ").Select((e, i) => (e, i)))
            {
                var splitRange = rawRange.Split("-").Select(int.Parse).ToArray();
                ranges[i] = (splitRange[0], splitRange[1]);
            }
            clsRanges[keyVals[0]] = ranges;
        }

        ticket = [.. splitData[1].Split(["\r\n", "\n"], SPLITOPT)[1].Split(',').Select(ulong.Parse)];
        nearTickets = [.. splitData[2]
            .Split(["\r\n", "\n"], SPLITOPT)
            .Skip(1)
            .Select(row => row.Split(',').Select(int.Parse).ToArray())];
        return (clsRanges, ticket, nearTickets);
    }

    static (int, int[][]) Part1(in Dictionary<string, (int, int)[]> clsRanges, in int[][] nearTickets)
    {
        List<int> invalidTicketValues = [];
        List<int[]> validTickets = [];

        foreach (var ticket in nearTickets)
        {
            var validTicket = true;
            foreach (var ticketValue in ticket)
            {
                var valid = false;
                foreach (var clsValue in clsRanges.Values)
                {
                    foreach (var range in clsValue)
                    {
                        var (min, max) = range;
                        if (min <= ticketValue && ticketValue <= max)
                        {
                            valid = true;
                            break;
                        }
                    }
                    if (valid) break;
                }
                if (!valid)
                {
                    invalidTicketValues.Add(ticketValue);
                    validTicket = false;
                }
            }
            if (validTicket) validTickets.Add(ticket);
        }
        return (invalidTicketValues.Sum(), [.. validTickets]);
    }

    static ulong Part2(
        Dictionary<string, (int, int)[]> clsRanges, in ulong[] ticket, in int[][] validNearTickets
        )
    {
        List<string> FitRanges(int[] nearTicket)
        {
            List<string> clss = [];
            foreach (var kv in clsRanges)
            {
                var valid = true;
                foreach (var ticketValue in nearTicket)
                {
                    var validRange = false;
                    foreach (var clsValue in kv.Value)
                    {
                        var (min, max) = clsValue;
                        if (min <= ticketValue && ticketValue <= max)
                        {
                            validRange = true;
                            break;
                        }
                    }
                    if (!validRange) valid = false;
                }
                if (valid) clss.Add(kv.Key);

            }
            return [.. clss];
        }

        List<List<string>> cls = [];
        for (int col = 0; col < ticket.Length; col++)
        {
            List<int> colField = [];
            for (int row = 0; row < validNearTickets.Length; row++) colField.Add(validNearTickets[row][col]);
            cls.Add(FitRanges([.. colField]));
        }

        while (true)
        {
            if (cls.All(e => e.Count == 1)) break;
            for (int i = 0; i < cls.Count; i++)
                if (cls[i].Count == 1)
                    for (int j = 0; j < cls.Count; j++)
                    {
                        if (i == j) continue;
                        cls[j].Remove(cls[i][0]);
                    }
        }
        return cls
            .SelectMany(elem => elem)
            .Zip(ticket)
            .Where(elem => elem.First.StartsWith("departure"))
            .Aggregate(1UL, (acc, elem) => acc * elem.Second);
    }
}
