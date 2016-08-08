extern crate ring;

use self::ring::digest;

use ObjectHasher;

pub struct Hasher {
    ctx: digest::Context,
}

impl Hasher {
    pub fn new() -> Hasher {
        Hasher::with_algorithm(&digest::SHA256)
    }

    pub fn with_algorithm(alg: &'static digest::Algorithm) -> Hasher {
        Hasher { ctx: digest::Context::new(&alg) }
    }
}

impl ObjectHasher for Hasher {
    fn write(&mut self, bytes: &[u8]) {
        self.ctx.update(bytes);
    }

    fn finish(self) -> Vec<u8> {
        let digest = self.ctx.finish();
        Vec::from(digest.as_ref())
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
    fn sha256_test_vector() {
        let mut hasher = Hasher::new();
        hasher.write(SHA256_VECTOR_STRING.as_bytes());
        assert_eq!(hasher.finish().to_hex(), SHA256_VECTOR_DIGEST);
    }
}
