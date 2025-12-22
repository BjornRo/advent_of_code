namespace aoc.Solutions;

using MT = (char c, byte R, byte C);
public class Day23
{
    public static void Solve()
    {
        var grid = File.ReadAllLines("in/d23t.txt").Select(x => x.ToCharArray()).ToArray();

        var piecesList = Enumerable.Range(0, 4).Select(_ => new List<MT>()).ToArray();
        foreach (var (i, row) in Utils.Enumerate(grid))
            foreach (var (j, c) in Utils.Enumerate(row))
                if ('A' <= grid[i][j] && grid[i][j] <= 'D') piecesList[grid[i][j] - 'A'].Add((grid[i][j], (byte)i, (byte)j));

        var pieces = piecesList.Select(x => x.ToArray()).ToArray();
        List<(int, int)> locked = [];
        while (true)
        {
            var finished = FinishedPiece(pieces);
            if (finished is null) break;
            pieces = LockInBurrow(pieces, finished.Value.B);
            locked.Add((finished.Value.G.gridRow, finished.Value.G.gridCol));
        }

        Console.WriteLine($"Part 1: {Part1(grid, locked, pieces)}");
        Console.WriteLine($"Part 2: {Part2()}");
    }
    static MT[][] LockInBurrow(MT[][] burrow, (int i, int j) toRemove)
    {
        var newBurrow = Utils.DeepCopy(burrow);
        newBurrow[toRemove.i] = [.. burrow[toRemove.i].Where((_, j) => j != toRemove.j)];
        return newBurrow;
    }
    static MT[][] MovePiece(MT[][] burrow, int i, int j, int row, int col)
    {
        var newBurrow = Utils.DeepCopy(burrow);
        newBurrow[i][j] = (burrow[i][j].c, (byte)row, (byte)col);
        return newBurrow;
    }
    static ((int, int) B, (int gridRow, int gridCol) G)? FinishedPiece(MT[][] burrow)
    {
        foreach (var (i, symbol) in Utils.Enumerate(burrow))
        {
            var rowSlot = symbol.Length + 1;
            foreach (var (j, (c, R, C)) in Utils.Enumerate(symbol))
                if (R == rowSlot && C == c switch { 'A' => 3, 'B' => 5, 'C' => 7, _ => 9 })
                    return ((i, j), (R, C));
        }
        return null;
    }
    static bool Finished(MT[][] burrow) => burrow.All(l => l.Length == 0);
    static long Part1(char[][] grid, List<(int, int)> locked, MT[][] pieces)
    {
        PriorityQueue<(MT[][], List<(int, int)>), int> queue = new([((pieces, locked), 0)]);
        HashSet<MT[][]> visited = [];

        long minCost = long.MaxValue;
        while (queue.TryDequeue(out var state, out var cost))
        {
            var (sBurrow, sLock) = state;
            if (Finished(sBurrow))
            {
                Utils.PrintM(sBurrow);
                Utils.PrintA(sLock);
                Console.WriteLine();
                if (cost < minCost) minCost = cost;
                continue;
            }
            if (cost >= minCost) continue;
            if (!visited.Add(sBurrow)) continue;

            foreach (var (i, symbols) in Utils.Enumerate(sBurrow))
            {
                foreach (var (j, symbol) in Utils.Enumerate(symbols))
                {
                    foreach (var (dr, dc) in Utils.Cross3(symbol.R, symbol.C))
                    {
                        if (grid[dr][dc] == '#') continue;
                        if (sLock.Contains((dr, dc))) continue;
                        var newBurrow = MovePiece(sBurrow, i, j, dr, dc);
                        if (FinishedPiece(newBurrow) is ((int, int) B, (int, int) G))
                        {
                            sLock = [.. sLock];
                            sLock.Add(G);
                            newBurrow = LockInBurrow(newBurrow, B);
                        }
                        var stepCost = symbol.c switch { 'A' => 1, 'B' => 1, 'C' => 1, _ => 1 };
                        queue.Enqueue((newBurrow, sLock), cost + stepCost);
                    }
                }
            }
        }
        return minCost;
    }
    static ulong Part2()
    {
        return 1;
    }
}
