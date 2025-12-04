namespace aoc.Solutions
{
    public class Day04
    {
        enum Elem
        {
            Empty = '.',
            Paper = '@',
        }
        public static void Solve()
        {
            Elem[][] inData = [.. File.ReadAllLines("in/d04.txt")
                    .Select(x => x.Select(c => c == '.' ? Elem.Empty : Elem.Paper).ToArray())];

            Console.WriteLine($"Part 1: {Part1(inData).Count}");
            Console.WriteLine($"Part 2: {Part2(inData)}");
        }
        static (int, int)? PaperDetector3000(int row, int col, Elem[][] matrix)
        {
            if (matrix[row][col] == Elem.Paper)
            {
                uint paperRolls = 0;
                for (int di = -1; di < 2; di++)
                {
                    for (int dj = -1; dj < 2; dj++)
                    {
                        if (di == 0 && dj == 0) continue;
                        if (0 > row + di || row + di >= matrix.Length) continue;
                        if (0 > col + dj || col + dj >= matrix[0].Length) continue;


                        if (matrix[row + di][col + dj] == Elem.Paper)
                        {
                            paperRolls += 1;
                        }
                    }
                }
                if (paperRolls < 4)
                {
                    return (row, col);
                }
            }
            return null;
        }
        static List<(int, int)> Part1(Elem[][] matrix)
        {
            List<(int, int)> accessibleRolls = [];

            for (int row = 0; row < matrix.Length; row++)
            {
                for (int col = 0; col < matrix[0].Length; col++)
                {
                    if (PaperDetector3000(row, col, matrix) is (int, int) result)
                    {
                        accessibleRolls.Add(result);
                    }
                }
            }
            return accessibleRolls;
        }

        static uint Part2(Elem[][] matrix)
        {
            uint rollinPaper = 0;

            while (true)
            {
                List<(int, int)> pendingRemoval = Part1(matrix);
                if (pendingRemoval.Count == 0) break;

                foreach (var (row, col) in pendingRemoval)
                {
                    matrix[row][col] = Elem.Empty;
                    rollinPaper += 1;
                }
            }

            return rollinPaper;
        }
    }
}