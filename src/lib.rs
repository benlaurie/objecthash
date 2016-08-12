extern crate unicode_normalization;

#[cfg(test)]
extern crate rustc_serialize;

pub mod hasher;
mod types;

#[cfg(feature = "objecthash-ring")]
pub fn digest<T: ObjectHash>(msg: &T) -> Vec<u8> {
    let mut hasher = hasher::default();
    msg.objecthash(&mut hasher);
    let digest = hasher.finish();
    Vec::from(digest.as_ref())
}

pub trait ObjectHasher {
    type D: AsRef<[u8]>;
    fn update(&mut self, bytes: &[u8]);
    fn update_nested<F>(&mut self, nested: F) where F: Fn(&mut Self);
    fn finish(self) -> Self::D;
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
