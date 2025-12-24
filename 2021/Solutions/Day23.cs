namespace aoc.Solutions;

public class Day23
{
    const byte _DOT = (byte)'.';
    const byte _A = (byte)'A';
    const byte _B = (byte)'B';
    const byte _C = (byte)'C';
    const byte _D = (byte)'D';
    public static void Solve()
    {
        var grid = File.ReadAllLines("in/d23.txt").Select(x => x.ToCharArray()).ToArray();
        var lc = Utils.Range(0, 3, true)
            .Select(i => Utils.Range(2, grid.Length - 1).Select(j => grid[j][3 + (i * 2)]).ToArray())
            .Select(x => x.Select(y => (byte)y).ToArray())
            .ToArray();

        var grid2 = grid[..3].Append([.. "  #D#C#B#A#"]).Append([.. "  #D#B#A#C#"]).Concat(grid[3..]).ToArray();
        var lc2 = Utils.Range(0, 3, true)
            .Select(i => Utils.Range(2, grid2.Length - 1).Select(j => grid2[j][3 + (i * 2)]).ToArray())
            .Select(x => x.Select(y => (byte)y).ToArray())
            .ToArray();

        byte[] hallway = [.. "..a.b.c.d..".ToCharArray().Select(x => (byte)x)];
        Console.WriteLine($"Part 1: {Solve(new State(lc[0], lc[1], lc[2], lc[3], hallway))}");
        Console.WriteLine($"Part 2: {Solve(new State(lc2[0], lc2[1], lc2[2], lc2[3], hallway))}");
    }
    static int CharCost(byte c) => c switch { _A => 1, _B => 10, _C => 100, _ => 1000 };
    struct State(byte[] BurrowA, byte[] BurrowB, byte[] BurrowC, byte[] BurrowD, byte[] Hallway)
    {
        public byte[] Hallway = Hallway;
        public readonly IEnumerable<(byte c, int burrowCol, byte burrowChar, int depth)> GetMovableBurrows()
        {
            byte[][] burrows = [BurrowA, BurrowB, BurrowC, BurrowD];
            byte[] mapping = [_A, _B, _C, _D];

            for (int burrowIndex = 0; burrowIndex < burrows.Length; burrowIndex++)
            {
                var burrow = burrows[burrowIndex];
                var m = mapping[burrowIndex];
                if (burrow.All(c => c == m || c == 0)) continue;
                for (int depth = 0; depth < BurrowA.Length; depth++)
                {
                    byte c = burrow[depth];
                    if (c == 0 || depth > 0 && burrow[..depth].Any(x => x != 0)) continue;
                    yield return (c, 3 + (burrowIndex * 2), m, depth);
                }
            }
        }
        public readonly byte[] GetCompartment(byte c) => c switch { _A => BurrowA, _B => BurrowB, _C => BurrowC, _ => BurrowD };
        public readonly int? CompartmentSpot(byte c)
        {
            var comp = GetCompartment(c);
            if (comp.Any(x => x != 0 && x != c)) return null;
            for (int i = comp.Length - 1; i >= 0; i--) if (comp[i] == 0) return i;
            return null;
        }
        public readonly bool Finished() =>
            BurrowA.All(c => c == _A) && BurrowB.All(c => c == _B) && BurrowC.All(c => c == _C) && BurrowD.All(c => c == _D);
        public readonly State Clone() => new([.. BurrowA], [.. BurrowB], [.. BurrowC], [.. BurrowD], [.. Hallway]);
        public readonly (ulong, ulong, ulong, ulong) Key()
        {
            ulong h0 = 0, h1 = 0, b0 = 0, b1 = 0;
            for (int i = 0; i < 8; i++) h0 |= (ulong)Hallway[i] << (i * 8);
            for (int i = 8; i < 11; i++) h1 |= (ulong)Hallway[i] << ((i - 8) * 8);
            for (int i = 0; i < BurrowA.Length; i++)
            {
                b0 |= (ulong)BurrowA[i] << (i * 8);
                b0 |= (ulong)BurrowB[i] << ((i + 4) * 8);
                b1 |= (ulong)BurrowC[i] << (i * 8);
                b1 |= (ulong)BurrowD[i] << ((i + 4) * 8);
            }
            return (h0, h1, b0, b1);
        }
    }
    static int Solve(State init)
    {
        PriorityQueue<State, int> queue = new([(init, 0)]);
        HashSet<(ulong, ulong, ulong, ulong)> visited = [];
        int minCost = int.MaxValue;
        while (queue.TryDequeue(out var state, out var cost))
        {
            if (state.Finished())
            {
                if (cost < minCost)
                {
                    minCost = cost;
                    break;
                }
                continue;
            }
            if (cost >= minCost || !visited.Add(state.Key())) continue;
            var hw = state.Hallway;
            foreach (var (c, burrowIndex, burrowChar, depth) in state.GetMovableBurrows())
                foreach (var dir in new int[] { -1, 1 })
                {
                    int steps = depth + 1;
                    for (int i = burrowIndex - 1 + dir; i >= 0 && i < hw.Length; i += dir)
                    {
                        if (_A <= hw[i] && hw[i] <= _D) break;
                        steps += 1;
                        if ((hw[i] - 32 == c) || hw[i] == _DOT)
                        {
                            var newState = state.Clone();
                            newState.Hallway[i] = c;
                            newState.GetCompartment(burrowChar)[depth] = 0;
                            queue.Enqueue(newState, cost + steps * CharCost(c));
                        }
                    }
                }
            foreach (var (k, c) in Utils.Enumerate(state.Hallway))
            {
                if (!(_A <= c && c <= _D)) continue;
                foreach (var dir in new int[] { -1, 1 })
                {
                    int steps = 0;
                    for (int i = k + dir; i >= 0 && i < hw.Length; i += dir)
                    {
                        if (_A <= hw[i] && hw[i] <= _D) break;
                        steps += 1;
                        if ((char)(hw[i] - 32) == c && state.CompartmentSpot(c) is int iSpot) // a,b,c,d
                        { // 1 is for iSpot, it costs to move to compartment
                            var newState = state.Clone();
                            newState.Hallway[k] = _DOT;
                            newState.GetCompartment(c)[iSpot] = c;
                            queue.Enqueue(newState, (steps + 1 + iSpot) * CharCost(c) + cost);
                        }
                    }
                }
            }
        }
        return minCost;
    }
}