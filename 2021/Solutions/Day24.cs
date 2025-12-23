namespace aoc.Solutions;

using Registers = Dictionary<byte, long>;
using IO = IEnumerable<long>;

public class Day24
{
    abstract record Ins
    {
        public abstract void Apply(Registers registers, IO IO);
    }
    record Inp(byte R) : Ins
    {
        public override void Apply(Registers registers, IO IO) => registers[R] = IO.Take(1).First();
    }

    record Add(byte R, byte S, bool Immediate) : Ins
    {
        public override void Apply(Registers registers, IO IO)
        {
            registers[R] = registers[R] + (Immediate ? S : registers[S]);
        }
    }

    record Mul(byte R, byte S, bool Immediate) : Ins
    {
        public override void Apply(Registers registers, IO IO)
        {
            registers[R] = registers[R] * (Immediate ? S : registers[S]);
        }
    }

    record Div(byte R, byte S, bool Immediate) : Ins
    {
        public override void Apply(Registers registers, IO IO)
        {
            registers[R] = registers[R] / (Immediate ? S : registers[S]);
        }
    }

    record Mod(byte R, byte S, bool Immediate) : Ins
    {
        public override void Apply(Registers registers, IO IO)
        {
            registers[R] = Utils.Mod(registers[R], Immediate ? S : registers[S]);
        }
    }

    record Eql(byte R, byte S, bool Immediate) : Ins
    {
        public override void Apply(Registers registers, IO IO)
        {
            registers[R] = registers[R] == (Immediate ? S : registers[S]) ? 1 : 0;
        }
    }
    public static void Solve()
    {
        var ins = File.ReadAllLines("in/d24t.txt").Select(x =>
        {
            static byte Imm(bool b, string[] m) => b && byte.TryParse(m[1], out var value) ? value : (byte)m[1][0];
            var res = x.Split(" ");
            var rem = res[1..];
            var r = (byte)res[0][0];
            var immediate = rem.Length == 2 && '0' <= rem[1][0] && rem[1][0] <= '9';
            return (Ins)(res[0] switch
            {
                "inp" => new Inp(r),
                "add" => new Add(r, Imm(immediate, rem), immediate),
                "mul" => new Mul(r, Imm(immediate, rem), immediate),
                "div" => new Div(r, Imm(immediate, rem), immediate),
                "mod" => new Mod(r, Imm(immediate, rem), immediate),
                _ => new Eql(r, Imm(immediate, rem), immediate)
            });
        })
        .Where(i => i switch
            { // Remove identities
                Add x => !x.Immediate || x.S != 0,
                Mul x => !x.Immediate || x.S != 1,
                Div x => !x.Immediate || x.S != 1,
                _ => true,
            })
        .ToArray();

        var regs = Utils.Range('a', 'z', true).ToDictionary(c => (byte)c, _ => 0L);

        Console.WriteLine($"Part 1: {Part1(ins, regs.ToDictionary(), IO("12345"))}");
        Console.WriteLine($"Part 2: {Part2()}");
    }
    static IO IO(string v) => v.Select(x => (long)(x - '0'));
    static ulong Part1(Ins[] instructions, Registers regs, IO io)
    {
        foreach (var ins in instructions)
        {
            ins.Apply(regs, io);
        }
        Utils.PrintA(regs.Keys);
        Utils.PrintA(regs.Values);
        Console.WriteLine(regs[(byte)'z']);
        return 1;
    }
    static ulong Part2()
    {
        return 1;
    }
}
