#[cfg(test)]
extern crate rustc_serialize;

pub mod hasher;
mod types;

#[cfg(feature = "objecthash-ring")]
pub fn digest<T: ObjectHash>(msg: &T) -> Vec<u8> {
    let mut hasher = hasher::default();
    msg.objecthash(&mut hasher);
    hasher.finish()
}

pub trait ObjectHasher {
    fn write(&mut self, bytes: &[u8]);
    fn finish(self) -> Vec<u8>;
}

pub trait ObjectHash {
    fn objecthash<H: ObjectHasher>(&self, hasher: &mut H);
}

#[cfg(test)]
#[cfg(feature = "objecthash-ring")]
mod tests {
    use digest;
    use rustc_serialize::hex::ToHex;

    #[test]
    fn digest_test() {
        let result = digest(&1000);
        assert_eq!(result.to_hex(),
                   "a3346d18105ef801c3598fec426dcc5d4be9d0374da5343f6c8dcbdf24cb8e0b");
    }
}
