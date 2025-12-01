namespace aoc.Solutions
{
    public class Day06
    {
        public static void Solve()
        {
            string inData = File.ReadAllText("in/d06.txt");

            List<List<string>> groups = [];
            foreach (var batch in inData.Split(["\r\n\r\n", "\n\n"], StringSplitOptions.RemoveEmptyEntries))
            {
                List<string> group = [];
                foreach (var person in batch.Split(["\r\n", "\n"], StringSplitOptions.RemoveEmptyEntries))
                    group.Add(person);
                groups.Add(group);
            }

            Console.WriteLine($"Part 1: {Part1(groups)}");
            Console.WriteLine($"Part 2: {Part2(groups)}");
        }


        static int Part1(in List<List<string>> groups)
        {
            int total = 0;
            foreach (var group in groups)
            {
                HashSet<char> answers = [];
                foreach (var answer in group)
                    foreach (char c in answer) answers.Add(c);
                total += answers.Count;
            }
            return total;
        }

        static int Part2(in List<List<string>> groups)
        {
            int total = 0;
            foreach (var group in groups)
            {
                int nGroup = group.Count;
                Dictionary<char, int> answers = [];
                foreach (var answer in group)
                    foreach (char c in answer)
                    {
                        if (!answers.TryGetValue(c, out int value))
                        {
                            value = 0;
                            answers[c] = value;
                        }
                        answers[c] = value + 1;
                    }
                foreach (int count in answers.Values) if (count == nGroup) total += 1;
            }
            return total;
        }
    }
}