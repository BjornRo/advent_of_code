namespace aoc.Solutions;

public partial class Day23
{
    const StringSplitOptions SPLITOPT = StringSplitOptions.RemoveEmptyEntries;
    static void Print(object? s)
    {
        Console.WriteLine(s);
    }
    static void Print()
    {
        Console.WriteLine();
    }

    public static void Solve()
    {
        int[] data = [.. File.ReadAllText("in/d23.txt").TrimEnd().ToCharArray().Select(e => e - '0')];

        Console.WriteLine($"Part 1: {Part1([.. data])}");
        // Console.WriteLine($"Part 2: {Part2(players).Item2}");
    }

    static string Part1(in int[] data)
    {
        var len = data.Length + 1;
        LinkedList<int> cards = new([.. data]);
        List<int> pickup = [];

        for (int i = 0; i < 100; i++)
        {
            pickup.Clear();
            var head = cards.First!;
            var next = head.Next!;
            for (int j = 0; j < 3; j++)
            {
                var nextNext = next.Next!;
                pickup.Add(next.Value);
                cards.Remove(next);
                next = nextNext;
            }
            cards.Remove(head);
            cards.AddLast(head);

            var value = head.Value - 1;
            while (pickup.Contains(value) || value == 0) value = ((value - 1) % len + len) % len;

            var destination = cards.Find(value)!;
            for (int j = 0; j < 3; j++)
            {
                cards.AddAfter(destination, pickup[j]);
                destination = destination.Next!;
            }
        }
        {
            var head = cards.First!;
            while (head.Value != 1)
            {
                var next = head.Next!;
                cards.Remove(head);
                cards.AddLast(head);
                head = next;
            }
        }
        cards.RemoveFirst();
        return string.Join("", cards);
    }

}
