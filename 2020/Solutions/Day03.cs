namespace aoc.Solutions
{
    public class Day03
    {
        public static void Solve()
        {
            string[] matrix = File.ReadAllLines("in/d03.txt");

            Console.WriteLine($"Part 1: {Slope(matrix, 3, 1)}");
            Console.WriteLine($"Part 2: {Part2(matrix)}");
        }

        static int Slope(in string[] matrix, in int col_offset, in int row_offset)
        {
            int total = 0;
            for (int i = row_offset; i < matrix.Length; i += row_offset)
            {
                int j = i * col_offset / row_offset % matrix[0].Length;
                if (matrix[i][j] == '#') total += 1;
            }
            return total;
        }

        static long Part2(in string[] matrix)
        {
            long total_prod = 1;
            var slopes = new (int, int)[] { (1, 1), (3, 1), (5, 1), (7, 1), (1, 2) };
            foreach (var (col, row) in slopes)
                total_prod *= Slope(matrix, col, row);
            return total_prod;
        }
    }
}