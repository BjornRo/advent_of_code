using aoc.Solutions;

if (int.TryParse(args[0], out int day))
{
    switch (day)
    {
        case 1: Day01.Solve(); break;
        case 2: Day02.Solve(); break;
        case 3: Day03.Solve(); break;
        case 4: Day04.Solve(); break;
        default: Console.WriteLine("Day not implemented."); break;
    }
}
