using System;
using System.IO;


namespace aoc.Solutions
{
    public class Day01
    {
        public static void Solve()
        {
            string[] lines = File.ReadAllLines("in/d01.txt");
            int sum = 0;

            foreach (var line in lines)
            {
                if (int.TryParse(line, out int num))
                    sum += num;
            }

            Console.WriteLine($"Day 1 solution: {sum}");
        }
    }
}