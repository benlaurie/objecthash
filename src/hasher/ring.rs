extern crate ring;

use Digest;
use ObjectHasher;

pub struct Hasher {
    ctx: ring::digest::Context,
}

impl Hasher {
    pub fn new(alg: &'static ring::digest::Algorithm) -> Hasher {
        Hasher { ctx: ring::digest::Context::new(alg) }
    }
}

impl Default for Hasher {
    fn default() -> Self {
        Self::new(&ring::digest::SHA256)
    }
}

impl ObjectHasher for Hasher {
    #[inline]
    fn output_len(&self) -> usize {
        self.ctx.algorithm.output_len
    }

    #[inline]
    fn update(&mut self, bytes: &[u8]) {
        self.ctx.update(bytes);
    }

    #[inline]
    fn update_nested<F>(&mut self, nested: F)
        where F: Fn(&mut Self)
    {
        let mut nested_hasher = Hasher::new(self.ctx.algorithm);
        nested(&mut nested_hasher);
        self.update(nested_hasher.finish().as_ref());
    }

    #[inline]
    fn finish(self) -> Digest {
        Digest::new(self.ctx.finish().as_ref()).unwrap()
    }
}

#[cfg(test)]
mod tests {
    use super::Hasher;
    use ObjectHasher;
    use rustc_serialize::hex::ToHex;

    // From Project NESSIE
    // https://www.cosic.esat.kuleuven.be/nessie/testvectors/hash/sha/Sha-2-256.unverified.test-vectors
    const SHA256_VECTOR_STRING: &'static str = "abcdefghijklmnopqrstuvwxyz";
    const SHA256_VECTOR_DIGEST: &'static str = "71c480df93d6ae2f1efad1447c66c9525e316218cf51fc8d9ed832f2daf18b73";

    #[test]
    fn sha256() {
        let mut hasher = Hasher::default();
        hasher.update(SHA256_VECTOR_STRING.as_bytes());
        assert_eq!(hasher.finish().as_ref().to_hex(), SHA256_VECTOR_DIGEST);
    }
}
