namespace aoc.Solutions
{
    public class Day06
    {
        public static void Solve()
        {
            string inData = File.ReadAllText("in/d06.txt");

            List<Dictionary<string, string>> passports = [];
            foreach (var batch in inData.Split(["\r\n\r\n", "\n\n"], StringSplitOptions.RemoveEmptyEntries))
            {
                Dictionary<string, string> passportData = [];
                foreach (var data in batch.Split(["\r\n", "\n"], StringSplitOptions.RemoveEmptyEntries))
                    foreach (var rawKeyValue in data.Split(" "))
                    {
                        string[] keyValue = rawKeyValue.Split(":");
                        passportData.Add(keyValue[0], keyValue[1]);
                    }
                passports.Add(passportData);
            }

            Console.WriteLine($"Part 1: {Part1(passports)}");
            Console.WriteLine($"Part 2: {Part2(passports)}");
        }

        static bool Part1Valid(in Dictionary<string, string> passport)
        {
            var count = passport.Count;
            return count == 8 || (count == 7 && !passport.ContainsKey("cid"));
        }

        static int Part1(in List<Dictionary<string, string>> passports)
        {
            int total = 0;
            foreach (var passport in passports)
                if (Part1Valid(passport))
                    total += 1;
            return total;
        }

        static int Part2(in List<Dictionary<string, string>> passports)
        {
            int total = 0;
            var hairColor = new HashSet<string> { "amb", "blu", "brn", "gry", "grn", "hzl", "oth" };
            foreach (var passport in passports)
            {
                if (!Part1Valid(passport)) continue;
                if (!passport.TryGetValue("byr", out string? v)
                    || !int.TryParse(v, out int r) || 1920 > r || r > 2002) continue;
                if (!passport.TryGetValue("iyr", out v)
                    || !int.TryParse(v, out r) || 2010 > r || r > 2020) continue;
                if (!passport.TryGetValue("eyr", out v)
                    || !int.TryParse(v, out r) || 2020 > r || r > 2030) continue;
                if (passport.TryGetValue("hgt", out v))
                {
                    if (!v.Contains("cm") && !v.Contains("in")) continue;
                    if (v.Contains("cm"))
                    {
                        if (!int.TryParse(v.Replace("cm", ""), out r) || 150 > r || r > 193) continue;
                    }
                    else if (!int.TryParse(v.Replace("in", ""), out r) || 59 > r || r > 76) continue;
                }
                else continue;
                if (!passport.TryGetValue("hcl", out v) || !v.Contains('#') || v.Length != 7) continue;
                if (!passport.TryGetValue("ecl", out v) || !hairColor.Contains(v)) continue;
                if (!passport.TryGetValue("pid", out v) || v.Length != 9 || !v.All(char.IsDigit)) continue;
                total += 1;
            }
            return total;
        }
    }
}