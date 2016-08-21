extern crate unicode_normalization;

#[cfg(test)]
extern crate rustc_serialize;

#[macro_export]
macro_rules! objecthash_dict_entry {
    ($key:expr, $value:expr) => {
        {
            let (key, value) = ($key, $value);
            let mut result = Vec::with_capacity(key.as_ref().len() + value.as_ref().len());
            result.extend_from_slice(&key.as_ref());
            result.extend_from_slice(&value.as_ref());
            result
        }
    }
}

#[macro_export]
macro_rules! objecthash_struct(
    { $hasher:expr, $($key:expr => $value:expr),+ } => {
        {
            let mut digests: Vec<Vec<u8>> = Vec::new();

            $(
                digests.push(objecthash_dict_entry!(
                    objecthash::digest(&String::from($key)),
                    objecthash::digest(&$value)
                ));
            )+

            digests.sort();

            $hasher.update(objecthash::types::DICT_TAG);
            for value in &digests {
                $hasher.update(&value);
            }
        }
     };
);

pub mod hasher;
pub mod types;

const MAX_OUTPUT_LEN: usize = 32;

pub struct Digest {
    output_len: usize,
    value: [u8; MAX_OUTPUT_LEN],
}

impl AsRef<[u8]> for Digest {
    #[inline(always)]
    fn as_ref(&self) -> &[u8] {
        &self.value[..self.output_len]
    }
}

#[cfg(feature = "objecthash-ring")]
pub fn digest<T: ObjectHash>(msg: &T) -> Digest {
    let mut hasher = hasher::default();
    msg.objecthash(&mut hasher);

    let output_len = hasher.output_len();
    let mut digest_bytes = [0u8; MAX_OUTPUT_LEN];
    digest_bytes.copy_from_slice(hasher.finish().as_ref());

    Digest {
        output_len: output_len,
        value: digest_bytes,
    }
}

pub trait ObjectHasher {
    type D: AsRef<[u8]>;
    fn output_len(&self) -> usize;
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
        assert_eq!(result.as_ref().to_hex(),
                   "a3346d18105ef801c3598fec426dcc5d4be9d0374da5343f6c8dcbdf24cb8e0b");
    }
}
