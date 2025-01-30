namespace aoc.Solutions;

public class Day17
{
    public static void Solve()
    {
        string[] matrix = File.ReadAllLines("in/d17t.txt");

        Console.WriteLine($"Part 1: {Part1([.. matrix.Select(row => row.ToCharArray())])}");
        // Console.WriteLine($"Part 2: {Part2([.. matrix.Select(row => row.ToCharArray())])}");
    }

    static int Part1(char[][] mat)
    {
        char[][] tmp_mat = new char[mat.Length][];
        for (int i = 0; i < mat.Length; i++) tmp_mat[i] = (char[])mat[i].Clone();

        HashSet<string> visited = [];
        while (true)
        {
            var key = string.Concat(mat.SelectMany(row => row));
            if (visited.Contains(key)) return mat.Sum(row => row.Count(c => c == '#'));
            visited.Add(key);

            for (int row = 0; row < mat.Length; row++)
                for (int col = 0; col < mat[0].Length; col++)
                {
                    var elem = mat[row][col];
                    if (elem == '.') continue;
                    var adjacent = 0;
                    for (int krow = row - 1; krow < row + 2; krow++)
                        for (int kcol = col - 1; kcol < col + 2; kcol++)
                        {
                            if (row == krow && col == kcol) continue;
                            if (0 <= krow && krow < mat.Length && 0 <= kcol && kcol < mat[0].Length)
                                if (mat[krow][kcol] == '#') adjacent += 1;
                        }
                    tmp_mat[row][col] = elem;
                    if (elem == 'L') { if (adjacent == 0) tmp_mat[row][col] = '#'; }
                    else if (elem == '#') { if (adjacent >= 4) tmp_mat[row][col] = 'L'; }
                }
            (tmp_mat, mat) = (mat, tmp_mat);
        }
    }
}


// static List<(int, int)>[,] GetVisibleSeats(char[][] grid)
// {
//     int rows = grid.Length;
//     int cols = grid[0].Length;
//     var directions = new (int, int)[]
//         { (-1, -1), (-1, 0), (-1, 1), (0, -1), (0, 1), (1, -1), (1, 0), (1, 1) };

//     var visibleSeats = new List<(int, int)>[rows, cols];
//     for (int r = 0; r < rows; r++)
//         for (int c = 0; c < cols; c++)
//         {
//             if (grid[r][c] == '.') continue;
//             visibleSeats[r, c] = [];

//             foreach (var (dr, dc) in directions)
//             {
//                 int nr = r + dr, nc = c + dc;
//                 while (0 <= nr && nr < rows && 0 <= nc && nc < cols)
//                 {
//                     if (grid[nr][nc] == 'L' || grid[nr][nc] == '#')
//                     {
//                         visibleSeats[r, c].Add((nr, nc));
//                         break;
//                     }
//                     nr += dr;
//                     nc += dc;
//                 }
//             }
//         }
//     return visibleSeats;
// }
