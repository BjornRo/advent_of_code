using System.Collections.Immutable;

namespace aoc.Solutions;

public class Day19
{
    record Scan(int X, int Y, int Z)
    {
        // public double Len = Math.Sqrt(X * X + Y * Y + Z * Z);
        public int LenSq() => X * X + Y * Y + Z * Z;
        public static Scan Init(string s)
        {
            var d = s.Split(",").Select(int.Parse).ToArray();
            return new Scan(d[0], d[1], d[2]);
        }
        public override string ToString() => $"{X},{Y},{Z}";
        public int Manhattan(Scan o) => Utils.Manhattan((X, Y, Z), (o.X, o.Y, o.Z));
        public Scan Sub(Scan o) => new(X - o.X, Y - o.Y, Z - o.Z);
        public Scan Add(Scan o) => new(X + o.X, Y + o.Y, Z + o.Z);
        public IEnumerable<Scan> Rotations()
        {
            static Scan RotX(Scan p) => new(p.X, -p.Z, p.Y);
            static Scan RotY(Scan p) => new(p.Z, p.Y, -p.X);
            static Scan RotZ(Scan p) => new(-p.Y, p.X, p.Z);
            HashSet<Scan> visited = [this];
            Queue<Scan> queue = new([this]);
            foreach (var _ in Enumerable.Range(0, 24))
            {
                int count = queue.Count;
                for (int i = 0; i < count; i++)
                {
                    var p = queue.Dequeue();
                    foreach (var rot in new Func<Scan, Scan>[] { RotX, RotY, RotZ })
                    {
                        var newP = rot(p);
                        if (!visited.Add(newP)) continue;
                        queue.Enqueue(newP);
                        yield return newP;
                    }
                }
            }
        }
    }
    public static void Solve()
    {
        var data = File.ReadAllText("in/d19t.txt")
            .Trim()
            .Replace("\r\n", "\n")
            .Split("\n\n")
            .Select(set => set.Split("\n").Skip(1).Select(Scan.Init).ToArray())
            .ToArray();

        Console.WriteLine($"Part 1: {Part1(data)}");
        // Console.WriteLine($"Part 2: {Part2(data)}");
    }
    static readonly Dictionary<Scan, Scan[]> memo = [];
    static ((Scan, Scan), (Scan, Scan))[] FindMatch(Scan[] a, Scan[] b)
    {
        static Scan[] MemoRot(Scan s) => memo.TryGetValue(s, out var rots) ? rots : (memo[s] = [.. s.Rotations()]);
        static bool RotationMatch(Scan a, Scan b) => MemoRot(a).Any(rotA => MemoRot(b).Any(rotB => rotA == rotB));
        static IEnumerable<((Scan, Scan), Scan)> Deltas(Scan[] scan)
        {
            for (int i = 0; i < scan.Length; i++)
                for (int j = 0; j < scan.Length; j++)
                    if (i != j) yield return ((scan[i], scan[j]), scan[i].Sub(scan[j]));
        }
        var aDeltas = Deltas(a).ToArray();
        var bDeltas = Deltas(b).ToArray();
        var filterDist = aDeltas.Select(d => d.Item2.LenSq()).Intersect(bDeltas.Select(d => d.Item2.LenSq()));

        List<((Scan, Scan), (Scan, Scan))> matchesA = [];
        foreach (var ((a0, a1), da) in aDeltas.Where(s => filterDist.Contains(s.Item2.LenSq())))
        {
            foreach (var ((b0, b1), db) in bDeltas)
            {
                if (da.LenSq() != db.LenSq()) continue;
                if (RotationMatch(da, db))
                {
                    matchesA.Add(((a0, a1), (b0, b1)));
                    break;
                }
            }
            if (matchesA.Count == 12) break;
        }
        return [.. matchesA];
    }
    // 735 too high
    static int Part1(Scan[][] scans)
    {
        HashSet<Scan> beacons = [.. scans[0]];
        // var transK = new (Scan, int)?[scans.Length];
        for (int i = 0; i < scans.Length - 1; i++)
        {
            for (int j = i + 1; j < scans.Length; j++)
            {
                // if (i == j) continue;
                var matches = FindMatch(scans[i], scans[j]);
                if (matches.Length == 0) continue;
                foreach (var k in Enumerable.Range(0, 23))
                {
                    int nMatch = 0;
                    foreach (var ((a0, a1), (b0, b1)) in matches)
                    {
                        var v0 = a0.Sub(a1);
                        if (b0.Sub(b1).Rotations().Skip(k).First() != v0) break;
                        nMatch += 1;
                    }
                    if (nMatch != 12) continue;
                    var T = matches[0].Item1.Item2.Sub(matches[0].Item2.Item2.Rotations().Skip(k).First());
                    // transK[j] = (T, k);
                    foreach (var ((a0, a1), (b0, b1)) in matches)
                    {
                        var bGlobal = b1.Rotations().Skip(k).First().Add(T);
                        if (a1 != bGlobal) Console.WriteLine("boo");
                        // Console.WriteLine(a1 == bGlobal);
                    }
                    foreach (var s in scans[j])
                    {
                        beacons.Add(s.Rotations().Skip(k).First().Add(T));
                    }
                    break;
                }
            }
        }
        foreach (var s in beacons.OrderBy(x => x.X))
        {
            Console.WriteLine(s);
        }


        // foreach (var (Tk, scanner) in transK.Zip(scans).Skip(1))
        // {
        //     if (Tk is (var T, var k))
        //     {
        //         var res = scanner.Select(s => s.Rotations().Skip(k).First().Add(T));
        //         beacons.UnionWith(res);
        //     }
        // }

        // foreach (var ((a0, a1), (b0, b1)) in matches)
        // {
        //     var bGlobal = b1.Rotations().Skip(k).First().Add(T);
        //     Console.WriteLine(a1 == bGlobal);
        // }
        // return 1;
        // var aT = scans[i].Zip(scans[j], (a, b) => a.Sub(b.Rotations().Skip(k).First())).ToArray();
        return beacons.Count;
    }
    static ulong Part2(ImmutableArray<ImmutableArray<Scan>> scans)
    {
        return 1;
    }
}
