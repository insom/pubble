use regex::Regex;
use std::fs::File;
use std::io::*;
use std::ops::*;

#[derive(Debug, PartialEq)]
enum Iota {
    Header(String),
    Blank,
    Graf(String),
    Verbata(String),
    Verbatim(String),
}

fn main() -> Result<()> {
    let date_re = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();
    let f = File::open("input.insom")?;
    let r = BufReader::new(f);
    let mut in_verbatim = false;

    let mut x: Vec<Iota> = r
        .lines()
        .map(|fie| match fie.unwrap() {
            x if date_re.is_match(x.as_str()) => (Iota::Header(x)),
            x if x == "----------" => (Iota::Blank),
            x if x == "```" => {
                in_verbatim = !in_verbatim;
                Iota::Blank
            }
            x if in_verbatim => Iota::Verbata(x),
            x if x == "" => Iota::Blank {},
            x => Iota::Graf(x),
        })
        .collect();

    let mut op: Vec<Iota> = Vec::new();
    let mut in_verb = false;
    let mut buf = String::new();
    for l in x {
        match l {
            Iota::Verbata(q) => { in_verb = true; buf = buf + &q + "\n"; },
            _ if in_verb => { in_verb = false; op.push(Iota::Verbatim(buf.to_string())); buf = String::new(); op.push(l) },
            _ => { op.push(l) },
        }
    }
    op = op.into_iter().filter(|r| *r != Iota::Blank).collect();

    println!("{:?}", op);

    Ok(())
}

// let v = textwrap::wrap(&fie, 10);
