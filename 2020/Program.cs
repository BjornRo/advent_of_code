using aoc.Solutions;

if (int.TryParse(args[0], out int day))
{
    switch (day)
    {
        case 1: Day01.Solve(); break;
        default: Console.WriteLine("Day not implemented."); break;
    }
}
