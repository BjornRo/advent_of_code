namespace aoc.Solutions
{
    public class Day05
    {
        public static void Solve()
        {
            string[] lines = File.ReadAllLines("in/d05.txt");

            var (p1, p2) = Solver(lines);
            Console.WriteLine($"Part 1: {p1}\nPart 2: {p2}");
        }

        static (int, int) SeatFinder(
            in int minRow, in int maxRow, in int minCol, in int maxCol, in string str, in int i
        )
        {
            if (i >= str.Length) return (minRow, minCol);
            if (i >= 7)
            {
                if (str[i] == 'L')
                    return SeatFinder(minRow, maxRow, minCol, (minCol + maxCol) / 2, str, i + 1);
                return SeatFinder(minRow, maxRow, (minCol + maxCol) / 2 + 1, maxCol, str, i + 1);
            }

            if (str[i] == 'F')
                return SeatFinder(minRow, (minRow + maxRow) / 2, minCol, maxCol, str, i + 1);
            return SeatFinder((minRow + maxRow) / 2 + 1, maxRow, minCol, maxCol, str, i + 1);
        }

        static (int, int) Solver(in string[] lines)
        {
            List<int> seats = [];
            foreach (var line in lines)
            {
                var (row, col) = SeatFinder(0, 127, 0, 7, line, 0);
                seats.Add(row * 8 + col);
            }
            seats.Sort();
            int seatID = -1;
            for (int i = 1; i < seats.Count - 1; i++)
                if (seats[i] - seats[i - 1] >= 2)
                {
                    seatID = seats[i] - 1;
                    break;
                }

            return (seats.Last(), seatID);
        }
    }
}