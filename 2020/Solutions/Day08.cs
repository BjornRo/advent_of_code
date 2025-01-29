namespace aoc.Solutions;

public class Day08
{
    enum OpCode
    {
        Acc,
        Jmp,
        Nop,

    }

    readonly struct Instruction
    {
        public readonly OpCode Op;
        public readonly int Value;

        public Instruction(string op, string value)
        {
            Op = op switch
            {
                "acc" => OpCode.Acc,
                "jmp" => OpCode.Jmp,
                _ => OpCode.Nop,
            };
            Value = int.Parse(value);
        }

        public Instruction(OpCode op, int value)
        {
            Op = op;
            Value = value;
        }
    }

    public static void Solve()
    {
        List<Instruction> instructions = [];
        foreach (var rawInstruction in File.ReadAllLines("in/d08.txt"))
        {
            string[] splitRawIns = rawInstruction.Split(" ");
            instructions.Add(new Instruction(splitRawIns[0], splitRawIns[1]));
        }

        Console.WriteLine($"Part 1: {Machine(instructions).Item2}");
        Console.WriteLine($"Part 2: {Part2(instructions)}");
    }

    static (bool, int) Machine(in List<Instruction> instructions)
    {
        HashSet<int> visited = [];
        int accumulator = 0;

        int pc = 0;
        while (pc < instructions.Count)
        {
            if (visited.Contains(pc)) return (false, accumulator);
            visited.Add(pc);

            var ins = instructions[pc];
            switch (ins.Op)
            {
                case OpCode.Jmp:
                    pc += ins.Value;
                    continue;
                case OpCode.Acc:
                    accumulator += ins.Value;
                    break;
            }
            pc += 1;
        }
        return (true, accumulator);
    }

    static int Part2(List<Instruction> instructions)
    {
        for (int i = 0; i < instructions.Count; i++)
        {
            var ins = instructions[i];
            if (ins.Op.Equals(OpCode.Jmp) || ins.Op.Equals(OpCode.Nop))
            {
                var newOp = ins.Op.Equals(OpCode.Jmp) ? OpCode.Nop : OpCode.Jmp;
                instructions[i] = new Instruction(newOp, ins.Value);

                var result = Machine(instructions);
                if (result.Item1) return result.Item2;

                instructions[i] = ins;
            }

        }
        return 0;
    }
}
