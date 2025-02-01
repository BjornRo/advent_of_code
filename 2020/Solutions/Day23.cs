namespace aoc.Solutions;

public partial class Day23
{
    public static void Solve()
    {
        int[] data = [.. File.ReadAllText("in/d23.txt").TrimEnd().ToCharArray().Select(e => e - '0')];

        Console.WriteLine($"Part 1: {Part1([.. data])}");
        Console.WriteLine($"Part 2: {Part2([.. data])}");
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

    static ulong Part2(in int[] data)
    {
        var len = 1000001;
        LinkedListNode<int>[] lookup = new LinkedListNode<int>[len];
        LinkedList<int> cards = new([.. data]);
        {
            var head = cards.First!;
            while (head != null)
            {
                lookup[head.Value] = head;
                head = head.Next;
            }
        }
        for (int i = 10; i <= 1000000; i++)
        {
            var node = new LinkedListNode<int>(i);
            cards.AddLast(node);
            lookup[node.Value] = node;
        }
        List<LinkedListNode<int>> pickup = [];

        for (int i = 0; i < 10000000; i++)
        {
            pickup.Clear();
            var head = cards.First!;
            var next = head.Next!;
            for (int j = 0; j < 3; j++)
            {
                var nextNext = next.Next!;
                pickup.Add(next);
                cards.Remove(next);
                next = nextNext;
            }
            cards.Remove(head);
            cards.AddLast(head);

            var value = head.Value - 1;
            while (true)
            {
                var contains = false;
                foreach (var node in pickup)
                {
                    if (node.Value == value)
                    {
                        contains = true;
                        break;
                    }
                }
                if (value != 0 && !contains) break;
                value = ((value - 1) % len + len) % len;
            }

            var destination = lookup[value];
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
        return (ulong)cards.First!.Value * (ulong)cards.First!.Next!.Value;
    }
}
