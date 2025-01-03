use chrono::{NaiveDateTime, TimeZone, Timelike, Utc};
use regex::Regex;
use std::{collections::HashMap, fs};

fn main() -> std::io::Result<()> {
    let contents = fs::read_to_string("in/d04.txt")?;

    let re = Regex::new(r"\[([0-9\-\s:]+)\].+(#\d+|falls|wakes)").unwrap();

    let mut partial_parsed = re
        .captures_iter(&contents)
        .map(|c| {
            let [time, rest] = c.extract().1;

            let date = NaiveDateTime::parse_from_str(time, "%Y-%m-%d %H:%M").unwrap();
            let absolute_time = date
                .and_utc()
                .signed_duration_since(Utc.with_ymd_and_hms(0, 1, 1, 0, 0, 0).unwrap())
                .num_minutes() as u64;

            (absolute_time, date.minute(), rest)
        })
        .collect::<Vec<(u64, u32, &str)>>();
    partial_parsed.sort_by(|a, b| a.0.cmp(&b.0));

    type GuardID = u64;
    type TotalAsleep = u32;
    type Minute = u64;
    type Counter = HashMap<Minute, u8>;
    let mut guards: HashMap<GuardID, (TotalAsleep, Counter)> = HashMap::new();

    let mut guard_id: u64 = partial_parsed[0].2[1..].parse().unwrap();
    let mut asleep_time = 0;

    for (_, minute, rest) in &partial_parsed[1..] {
        match rest.chars().nth(0).unwrap() {
            'f' => asleep_time = *minute,
            'w' => {
                let entry = guards.entry(guard_id).or_insert((0, HashMap::new()));
                entry.0 += *minute - asleep_time;
                for i in asleep_time..*minute {
                    *entry.1.entry(i as u64).or_insert(0) += 1;
                }
            }
            _ => guard_id = rest[1..].parse().unwrap(),
        }
    }

    let p1_guard = guards
        .iter()
        .map(|(guard_id, (total, inner_map))| {
            let minute = inner_map.iter().max_by_key(|item| item.1).unwrap().0;
            (guard_id, minute, total)
        })
        .max_by_key(|item| item.2)
        .unwrap();

    let p2_guard = guards
        .iter()
        .map(|(guard_id, (_, inner_map))| {
            let (time, count) = inner_map.iter().max_by_key(|item| item.1).unwrap();
            (guard_id, time, count)
        })
        .max_by_key(|item| item.2)
        .unwrap();

    println!("Part 1: {}", p1_guard.0 * p1_guard.1);
    println!("Part 2: {}", p2_guard.0 * p2_guard.1);
    Ok(())
}
