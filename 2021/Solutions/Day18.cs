namespace aoc.Solutions;

public class Day18
{
    abstract class Tree
    {
        public Tree? Parent;
        abstract public bool Explode(int depth = 0);
        public abstract bool Split();
        abstract public int Depth();
        public abstract int Result();
        public abstract override string ToString();
    }
    class Leaf(int Value) : Tree
    {
        public int Value { get; set; } = Value;
        public override bool Equals(object? obj) => obj is Leaf other && Value == other.Value;
        public override int GetHashCode() => Value;
        public override int Result() => Value;
        public override int Depth() => 0;
        public override bool Explode(int depth = 0) => false;
        public override bool Split()
        {
            if (Value < 10) return false;
            var node = Node.Init(
                new Leaf(Value / 2),
                new Leaf((Value + 1) / 2),
                Parent
            );
            if (Parent is Node p)
            {
                if (p.Left == this) p.Left = node;
                else p.Right = node;
            }
            return true;
        }

        public override string ToString() => Value.ToString();
    }
    class Node(Tree Left, Tree Right) : Tree
    {
        public Tree Left { get; set; } = Left;
        public Tree Right { get; set; } = Right;
        public static Node Init(Tree left, Tree right, Tree? parent = null)
        {
            var node = new Node(left, right) { Parent = parent };
            left.Parent = node;
            right.Parent = node;
            return node;
        }
        public override bool Equals(object? obj) => obj is Node other && Equals(Left, other.Left) && Equals(Right, other.Right);
        public override int GetHashCode() => HashCode.Combine(Left, Right);
        public override int Result() => 3 * Left.Result() + 2 * Right.Result();
        public Node Add(Tree elem) => Init(this, elem);
        public override int Depth() => 1 + Math.Max(Left.Depth(), Right.Depth());
        public override bool Explode(int depth = 0)
        {
            if (depth >= 4 && Left is Leaf l && Right is Leaf r)
            {
                if (FindLeaf(true) is Leaf ln) ln.Value += l.Value;
                if (FindLeaf(false) is Leaf rn) rn.Value += r.Value;
                var zero = new Leaf(0) { Parent = Parent };
                if (Parent is Node n) if (n.Left == this) n.Left = zero; else n.Right = zero;
                return true;
            }
            return Left.Explode(depth + 1) || Right.Explode(depth + 1);
        }
        public Node Reduce()
        {
            while (true)
            {
                if (Explode()) continue;
                if (Split()) continue;
                return this;
            }
        }
        public override bool Split() => Left.Split() || Right.Split();
        Leaf? FindLeaf(bool left)
        {
            Tree cur = this;
            while (cur.Parent is Node p)
            {
                if ((left && cur == p.Right) || (!left && cur == p.Left))
                {
                    cur = left ? p.Left : p.Right;
                    while (cur is Node n) cur = left ? n.Right : n.Left;
                    return cur as Leaf;
                }
                cur = p;
            }
            return null;
        }
        public override string ToString() => $"[{Left},{Right}]";
    }
    static Tree Parse(string row)
    {
        static (Tree, int) _Parse(string row, int index)
        {
            for (int i = index; i < row.Length; i++)
                switch (row[i])
                {
                    case '[':
                        (var left, i) = _Parse(row, i + 1);
                        (var right, i) = _Parse(row, i);
                        return (Node.Init(left, right), i);
                    case ']':
                    case ',':
                        break;
                    default: // Number
                        return (new Leaf(row[i] - '0'), i + 2);
                }
            throw new Exception("No");
        }
        return _Parse(row, 0).Item1;
    }
    static Tree Clone(Tree t) => Parse(t.ToString());
    public static void Solve()
    {
        var tree = File.ReadAllLines("in/d18.txt").Select(Parse).ToArray();

        Console.WriteLine($"Part 1: {Part1([.. tree.Select(Clone)])}");
        Console.WriteLine($"Part 2: {Part2([.. tree.Select(Clone)])}");
    }
    static int Part1(Tree[] tree) =>
        tree.Skip(1).Aggregate((Node)tree[0], (st, next) => st.Add(next).Reduce()).Result();

    static int Part2(Tree[] tree)
    {
        int max = 0;
        for (int i = 0; i < tree.Length; i++)
            for (int j = 0; j < tree.Length; j++)
                if (i != j)
                    max = Math.Max(max, ((Node)Clone(tree[i])).Add(Clone(tree[j])).Reduce().Result());
        return max;
    }
}