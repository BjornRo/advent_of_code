namespace aoc.Solutions
{
    public class Day05
    {
        public static void Solve()
        {
            string[] lines = File.ReadAllLines("in/d05.txt");

            var (p1, p2) = Solver(lines);
            Console.WriteLine($"Part 1: {p1}");
            Console.WriteLine($"Part 2: {p2}");
        }


        static (int, int) SeatFinder(in int minRow, in int maxRow, in int minCol, in int maxCol, string str, int i)
        {
            if (i >= str.Length) return (minRow, minCol);
            if (i >= 7)
            {
                if (str[i] == 'L')
                    return SeatFinder(minRow, maxRow, minCol, (minCol + maxCol) / 2, str, i + 1);
                else
                    return SeatFinder(minRow, maxRow, (minCol + maxCol) / 2 + 1, maxCol, str, i + 1);
            }

            if (str[i] == 'F')
                return SeatFinder(minRow, (minRow + maxRow) / 2, minCol, maxCol, str, i + 1);
            else
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

        // static int Part2(in List<Dictionary<string, string>> passports)
        // {
        //     int total = 0;
        //     var hairColor = new HashSet<string> { "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
        //     foreach (var passport in passports)
        //     {
        //         if (!Part1Valid(passport)) continue;
        //         if (!passport.TryGetValue("byr", out string? v)
        //             || !int.TryParse(v, out int r) || 1920 > r || r > 2002) continue;
        //         if (!passport.TryGetValue("iyr", out v)
        //             || !int.TryParse(v, out r) || 2010 > r || r > 2020) continue;
        //         if (!passport.TryGetValue("eyr", out v)
        //             || !int.TryParse(v, out r) || 2020 > r || r > 2030) continue;
        //         if (passport.TryGetValue("hgt", out v))
        //         {
        //             if (!v.Contains("cm") && !v.Contains("in")) continue;
        //             if (v.Contains("cm"))
        //             {
        //                 if (!int.TryParse(v.Replace("cm", ""), out r) || 150 > r || r > 193) continue;
        //             }
        //             else if (!int.TryParse(v.Replace("in", ""), out r) || 59 > r || r > 76) continue;
        //         }
        //         else continue;
        //         if (!passport.TryGetValue("hcl", out v) || !v.Contains('#') || v.Length != 7) continue;
        //         if (!passport.TryGetValue("ecl", out v) || !hairColor.Contains(v)) continue;
        //         if (!passport.TryGetValue("pid", out v) || v.Length != 9 || !v.All(char.IsDigit)) continue;
        //         total += 1;
        //     }
        //     return total;
        // }
    }
}