extern crate crypto;
extern crate num;

use crypto::digest::Digest;
use num::bigint::{BigInt, ToBigInt};

pub enum Node {
    Bool(bool),
    Int(BigInt),
    Float(f64),
    String(String),
    List(Vec<Node>),
    Null,
    // TODO: Support dictionaries.
}

pub type Hash = [u8; 32];

impl Node {
    pub fn hash(&self) -> Hash {
        match self {
            &Node::Bool(v) => {
                let mut bb = vec!['b' as u8];
                if v {
                    bb.push('1' as u8)
                } else {
                    bb.push('0' as u8)
                };
                hash(&bb)
            }
            &Node::Int(ref v) => {
                let mut bb = vec!['i' as u8];
                bb.extend(format!("{}", v).bytes());
                hash(&bb)
            }
            &Node::Float(f) => {
                let mut f = f;
                let mut bb = vec!['f' as u8];
                if f < 0.0 {
                    f = -f;
                    bb.push('-' as u8);
                } else {
                    bb.push('+' as u8);
                }

                {
                    let mut e = 0;
                    while f > 1.0 {
                        f /= 2.0;
                        e += 1;
                    }
                    while f <= 0.5 {
                        f *= 2.0;
                        e -= 1;
                    }
                    bb.extend(format!("{}:", e).bytes());
                }

                while f != 0.0 {
                    if f >= 1.0 {
                        bb.push('1' as u8);
                        f -= 1.0;
                    } else {
                        bb.push('0' as u8);
                    }
                    f *= 2.0;
                }

                hash(&bb)
            }
            &Node::String(ref v) => {
                let mut bb = vec!['u' as u8];
                bb.extend(v.bytes());
                hash(&bb)
            }
            &Node::List(ref v) => {
                let mut bb = vec!['l' as u8];
                for n in v.iter() {
                    bb.extend(&n.hash());
                }
                hash(&bb)
            }
            &Node::Null => hash(&['n' as u8]),
        }
    }
}

fn hash(v: &[u8]) -> Hash {
    let mut hasher = crypto::sha2::Sha256::new();
    hasher.input(v);
    let mut h = [0; 32];
    hasher.result(&mut h);
    h
}

fn format_hash(h: Hash) -> String {
    let mut out = String::new();
    for b in h.iter() {
        out += &format!("{:02x}", b)
    }
    out
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bool_false() {
        test(
            Node::Bool(false),
            "c02c0b965e023abee808f2b548d8d5193a8b5229be6f3121a6f16e2d41a449b3".to_string(),
        );
    }

    #[test]
    fn bool_true() {
        test(
            Node::Bool(true),
            "7dc96f776c8423e57a2785489a3f9c43fb6e756876d6ad9a9cac4aa4e72ec193".to_string(),
        );
    }

    #[test]
    fn float_positive() {
        test(
            Node::Float(1.2345),
            "844e08b1195a93563db4e5d4faa59759ba0e0397caf065f3b6bc0825499754e0".to_string(),
        );
    }

    #[test]
    fn float_negative() {
        test(
            Node::Float(-10.1234),
            "59b49ae24998519925833e3ff56727e5d4868aba4ecf4c53653638ebff53c366".to_string(),
        );
    }

    #[test]
    fn empty_list() {
        test(
            Node::List(vec![]),
            "acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0".to_string(),
        );
    }

    #[test]
    fn list_with_null() {
        test(
            Node::List(vec![Node::Null]),
            "5fb858ed3ef4275e64c2d5c44b77534181f7722b7765288e76924ce2f9f7f7db".to_string(),
        );
    }

    #[ignore]
    #[test]
    fn list_with_int_1() {
        test(
            Node::List(vec![Node::Int(123.to_bigint().unwrap())]),
            "2e72db006266ed9cdaa353aa22b9213e8a3c69c838349437c06896b1b34cee36".to_string(),
        );
    }

    #[ignore]
    #[test]
    fn list_with_int_2() {
        test(
            Node::List(vec![
                Node::Int(1.to_bigint().unwrap()),
                Node::Int(2.to_bigint().unwrap()),
                Node::Int(3.to_bigint().unwrap()),
            ]),
            "925d474ac71f6e8cb35dd951d123944f7cabc5cda9a043cf38cd638cc0158db0".to_string(),
        );
    }

    #[ignore]
    #[test]
    fn list_with_int_3() {
        test(
            Node::List(vec![Node::Int(123456789012345.to_bigint().unwrap())]),
            "f446de5475e2f24c0a2b0cd87350927f0a2870d1bb9cbaa794e789806e4c0836".to_string(),
        );
    }

    #[ignore]
    #[test]
    fn list_with_int_4() {
        test(
            Node::List(vec![
                Node::Int(123456789012345.to_bigint().unwrap()),
                Node::Int(678901234567890.to_bigint().unwrap()),
            ]),
            "d4cca471f1c68f62fbc815b88effa7e52e79d110419a7c64c1ebb107b07f7f56".to_string(),
        );
    }

    #[test]
    fn list_with_string_1() {
        test(
            Node::List(vec![Node::String("foo".to_string())]),
            "268bc27d4974d9d576222e4cdbb8f7c6bd6791894098645a19eeca9c102d0964".to_string(),
        );
    }

    #[test]
    fn list_with_string_2() {
        test(
            Node::List(vec![
                Node::String("foo".to_string()),
                Node::String("bar".to_string()),
            ]),
            "32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2".to_string(),
        );
    }

    #[test]
    fn unicode_1() {
        test(
            Node::String("ԱԲաբ".to_string()),
            "2a2a4485a4e338d8df683971956b1090d2f5d33955a81ecaad1a75125f7a316c".to_string(),
        );
    }

    #[test]
    fn unicode_2() {
        test(
            Node::String("\u{03d3}".to_string()),
            "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d".to_string(),
        );
    }

    #[test]
    fn unicode_3() {
        test(
            Node::String("\u{03d2}\u{0301}".to_string()),
            "42d5b13fb064849a988a86eb7650a22881c0a9ecf77057a1b07ab0dad385889c".to_string(),
        );
    }

    fn test(v: Node, h: String) {
        assert_eq!(h, format_hash(v.hash()));
    }
}
