using System.Collections.Immutable;
using System.Diagnostics;
namespace aoc.Solutions;

public class Day19
{
    record Scan(int X, int Y, int Z)
    {
        public int LenSq() => X * X + Y * Y + Z * Z;
        public static Scan Init(string s)
        {
            var d = s.Split(",").Select(int.Parse).ToArray();
            return new(d[0], d[1], d[2]);
        }
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
        static readonly Dictionary<Scan, HashSet<Scan>> memoRot = [];
        public HashSet<Scan> RotationSet() =>
            memoRot.TryGetValue(this, out var result) ? result : memoRot[this] = [.. Rotations()];
        private Scan[] Rots = [];
        public Scan[] Rotations() => Rots.Length == 0 ? Rots = [.. IRotations()] : Rots;
        public Scan Rotate(int k) => Rotations().Skip(k).First();
        private IEnumerable<Scan> IRotations()
        {
            static Scan RotX(Scan p) => new(p.X, -p.Z, p.Y);
            static Scan RotY(Scan p) => new(p.Z, p.Y, -p.X);
            static Scan RotZ(Scan p) => new(-p.Y, p.X, p.Z);
            HashSet<Scan> visited = [this];
            Queue<Scan> queue = new([this]);
            foreach (var _ in Enumerable.Range(0, 24))
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
    public static void Solve()
    {
        var data = File.ReadAllText("in/d19.txt")
            .Trim()
            .Replace("\r\n", "\n")
            .Split("\n\n")
            .Select(set => set.Split("\n").Skip(1).Select(Scan.Init).ToArray())
            .ToArray();

        var mappings = GenerateMappings(data);
        Console.WriteLine($"Part 1: {Part1(data, mappings)}");
        Console.WriteLine($"Part 2: {Part2(data, mappings)}");
    }
    static ((Scan, Scan), (Scan, Scan))[] FindMatch(Scan[] a, Scan[] b)
    {
        static IEnumerable<((Scan, Scan), Scan)> Deltas(Scan[] scan)
        {
            for (int i = 0; i < scan.Length; i++)
                for (int j = 0; j < scan.Length; j++)
                    if (i != j) yield return ((scan[i], scan[j]), scan[i].Sub(scan[j]));
        }
        var bDeltas = Deltas(b).ToArray();
        List<((Scan, Scan), (Scan, Scan))> matchesA = [];
        foreach (var ((a0, a1), da) in Deltas(a))
        {
            foreach (var ((b0, b1), db) in bDeltas)
                if (da.LenSq() == db.LenSq() && da.RotationSet().Overlaps(db.RotationSet()))
                    matchesA.Add(((a0, a1), (b0, b1)));
            if (matchesA.Count == 12) break;
        }
        return [.. matchesA];
    }
    static (int, int)[] FindMapping(Dictionary<(int, int), (Scan, int)> mappings, int i)
    {
        Queue<(int, List<(int, int)>)> queue = new([(i, [])]);
        HashSet<int> visited = [i];
        while (queue.TryDequeue(out var state))
        {
            var (index, path) = state;
            if (index == 0) return [.. path];
            foreach (var ((from, to), _) in mappings)
                if (from == index && visited.Add(to))
                    queue.Enqueue((to, [.. path, (from, to)]));
        }
        throw new Exception("No");
    }
    static Dictionary<(int, int), (Scan, int)> GenerateMappings(Scan[][] scans)
    {
        int[] kInvs = Scan.InvRot();
        Dictionary<(int, int), (Scan, int)> mappings = [];
        for (int i = 0; i < scans.Length - 1; i++)
            for (int j = i + 1; j < scans.Length; j++)
            {
                var matches = FindMatch(scans[i], scans[j]);
                if (matches.Length != 12) continue;
                foreach (var k in Enumerable.Range(0, 23))
                {
                    int nMatch = 0;
                    foreach (var ((a0, a1), (b0, b1)) in matches)
                        if (b0.Sub(b1).Rotate(k) != a0.Sub(a1)) break;
                        else nMatch += 1;
                    if (nMatch != 12) continue;
                    var T = matches[0].Item1.Item2.Sub(matches[0].Item2.Item2.Rotate(k));
                    mappings[(j, i)] = (T, k);
                    mappings[(i, j)] = (T.Rotate(kInvs[k]).Neg(), kInvs[k]);
                    break;
                }
            }
        return mappings;
    }
    static int Part1(Scan[][] scans, Dictionary<(int, int), (Scan, int)> mappings)
    {
        HashSet<Scan> beacons = [.. scans[0]];
        foreach (var (i, scan) in scans.Skip(1).Select((s, i) => (i + 1, s)))
            beacons.UnionWith(scan.Select(s => FindMapping(mappings, i).Aggregate(s, (agg, step) =>
            {
                var (T, k) = mappings[step];
                return agg.Rotate(k).Add(T);
            })));
        return beacons.Count;
    }
    static int Part2(Scan[][] scans, Dictionary<(int, int), (Scan T, int k)> mappings)
    {
        Scan[] scanLoc = [new(0,0,0),.. Enumerable.Range(1, scans.Length - 1)
            .Select(i => {
                var m = FindMapping(mappings, i).Select(j => mappings[j]).ToArray();
                return m.Skip(1).Aggregate(m[0].T, (agg, Tk) => agg.Rotate(Tk.k).Add(Tk.T));
            })];

        int max = 0;
        for (int i = 0; i < scanLoc.Length - 1; i++)
            for (int j = i + 1; j < scanLoc.Length; j++)
                max = Math.Max(scanLoc[i].Manhattan(scanLoc[j]), max);
        return max;
    }
}