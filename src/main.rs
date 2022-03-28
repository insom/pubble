use regex::Regex;
use std::fs::File;
use std::io::*;

#[derive(Debug, PartialEq)]
enum Iota {
    Header(String),
    Blank,
    Graf(String),
    Verbata(String),
    Verbatim(String),
}

fn parse_insom_file(br: BufReader<File>) -> Vec<Iota> {
    let mut in_verbatim = false;
    let date_re = Regex::new(r"^\d{4}-\d{2}-\d{2}$").unwrap();

    let first_pass: Vec<Iota> = br
        .lines()
        .map(|line| match line.unwrap() {
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

    let mut output: Vec<Iota> = Vec::new();
    let mut in_verb = false;
    let mut buf = String::new();
    for iota_ in first_pass {
        match iota_ {
            Iota::Verbata(q) => {
                in_verb = true;
                buf = buf + &q + "\n";
            }
            _ if in_verb => {
                in_verb = false;
                output.push(Iota::Verbatim(buf.to_string()));
                buf = String::new();
                output.push(iota_)
            }
            _ => output.push(iota_),
        }
    }
    output.into_iter().filter(|r| *r != Iota::Blank).collect()
}

fn main() {
    let f = File::open("input.insom").unwrap();
    let br = BufReader::new(f);

    println!("{:?}", parse_insom_file(br));
}

// let v = textwrap::wrap(&fie, 10);
