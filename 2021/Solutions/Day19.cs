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
            return new(d[0], d[1], d[2]);
        }
        public override string ToString() => $"{X},{Y},{Z}";
        public int Manhattan(Scan o) => Utils.Manhattan((X, Y, Z), (o.X, o.Y, o.Z));
        public Scan Sub(Scan o) => new(X - o.X, Y - o.Y, Z - o.Z);
        public Scan Add(Scan o) => new(X + o.X, Y + o.Y, Z + o.Z);
        public Scan Neg() => new(-X, -Y, -Z);
        public static int[] InvRot()
        {
            var p = new Scan(1, 2, 3);
            var rots = p.Rotations();
            var inv = new int[rots.Length];

            for (int i = 0; i < rots.Length; i++)
                for (int j = 0; j < rots.Length; j++)
                    if (rots[j].Rotate(i) == p)
                    {
                        inv[i] = j;
                        break;
                    }
            return inv;
        }
        public virtual bool Equals(Scan? o) => o is not null && X == o.X && Y == o.Y && Z == o.Z;
        public override int GetHashCode() => HashCode.Combine(X, Y, Z);
        private Scan[] Rots = [];
        public Scan[] Rotations()
        {
            if (Rots.Length == 0) Rots = [.. IRotations()];
            return Rots;
        }
        public Scan Rotate(int k) => Rotations().Skip(k).First();
        private IEnumerable<Scan> IRotations()
        {
            static Scan RotX(Scan p) => new(p.X, -p.Z, p.Y);
            static Scan RotY(Scan p) => new(p.Z, p.Y, -p.X);
            static Scan RotZ(Scan p) => new(-p.Y, p.X, p.Z);
            HashSet<Scan> visited = [this];
            Queue<Scan> queue = new([this]);
            yield return this;
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
        int[] kInvs = Scan.InvRot();
        Dictionary<(int, int), (Scan, int)> mappings = [];
        for (int i = 0; i < scans.Length - 1; i++)
        {
            for (int j = i + 1; j < scans.Length; j++)
            {
                if (i == j) continue;
                var matches = FindMatch(scans[i], scans[j]);
                if (matches.Length != 12) continue;
                foreach (var k in Enumerable.Range(0, 23))
                {
                    int nMatch = 0;
                    foreach (var ((a0, a1), (b0, b1)) in matches)
                    {
                        var v0 = a0.Sub(a1);
                        // Console.WriteLine(a1.Rotations().Length);
                        if (b0.Sub(b1).Rotations().Skip(k).First() != v0) break;
                        nMatch += 1;
                    }
                    if (nMatch != 12) continue;
                    var T = matches[0].Item1.Item2.Sub(matches[0].Item2.Item2.Rotations().Skip(k).First());
                    mappings[(j, i)] = (T, k);
                    mappings[(i, j)] = (T.Rotate(kInvs[k]).Neg(), kInvs[k]);
                    break;
                }
            }
        }
        /*
               // (1, 0)
               // (68,-1246,-43, 7)
               // (0, 1)
               // (68,1246,-43, 7)

               // (2, 1)
               // (-1037,41,-1272, 11)
               // (1, 2)
               // (1037,-1272,-41, 1)

               // (4, 1)
               // (88,113,-1104, 5)
               // (1, 4)
               // (-1104,-88,113, 20)

               // (4, 2)
               // (1125,-168,72, 13)
               // (2, 4)
               // (168,-1125,72, 13)

               // (0, 4)
               // (-1061,-20,-1133, 22)
               // (4, 0)
               // (-20,-1133,1061, 9)

               // (4, 3)
               // (-72,1247,-1081, 5)
               // (3, 4)
               // (-1081,72,1247, 20)
       */
        // foreach (var ((i, j), (T, k)) in mappings)
        // {
        //     Console.WriteLine((i, j));
        //     Console.WriteLine((T, k));
        //     Console.WriteLine();
        // }
        foreach (var ((i, j), (T, k)) in mappings)
        {
            // beacons.Add(s.Rotations().Skip(k).First().Add(T));
        }

        (int, int)[] FindMapping(int i)
        {
            Queue<(int, List<(int, int)>)> queue = new([(i, [])]);
            HashSet<int> visited = [i];

            while (queue.TryDequeue(out var state))
            {
                var (index, path) = state;
                if (index == 0) return [.. path];
                foreach (var ((from, to), _) in mappings)
                {
                    if (from != index) continue;
                    if (visited.Contains(to)) continue;
                    visited.Add(to);
                    var newPath = new List<(int, int)>(path) { (from, to) };
                    queue.Enqueue((to, newPath));
                }
            }
            throw new Exception("No");
        }

        HashSet<Scan> beacons = [.. scans[0]];
        foreach (var (i, scan) in scans.Skip(1).Select((s, i) => (i + 1, s)))
        {
            var map = FindMapping(i);
            beacons.UnionWith(scan.Select(s => map.Aggregate(s, (agg, step) =>
            {
                var (T, k) = mappings[step];
                return agg.Rotate(k).Add(T);
            })));
        }

        // foreach (var s in beacons.OrderBy(x => x.X))
        // {
        //     Console.WriteLine(s);
        // }


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
