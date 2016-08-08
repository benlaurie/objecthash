use {ObjectHash, ObjectHasher};

macro_rules! impl_inttype (($inttype:ident) => (
    impl ObjectHash for $inttype {
        fn objecthash<H: ObjectHasher>(&self, hasher: &mut H) {
            hasher.write(b"i");
            hasher.write(self.to_string().as_bytes())
        }
    }
));

impl_inttype!(i8);
impl_inttype!(i16);
impl_inttype!(i32);
impl_inttype!(i64);
impl_inttype!(u8);
impl_inttype!(u16);
impl_inttype!(u32);
impl_inttype!(u64);
impl_inttype!(isize);
impl_inttype!(usize);

#[cfg(test)]
#[cfg(feature = "objecthash-ring")]
mod tests {
    use {ObjectHash, ObjectHasher};
    use hasher;
    use rustc_serialize::hex::ToHex;

    fn test_i32(val: i32, expected_digest_hex: &str) {
        let mut hasher = hasher::default();
        val.objecthash(&mut hasher);
        assert_eq!(hasher.finish().to_hex(), expected_digest_hex);
    }

    fn test_u32(val: u32, expected_digest_hex: &str) {
        let mut hasher = hasher::default();
        val.objecthash(&mut hasher);
        assert_eq!(hasher.finish().to_hex(), expected_digest_hex);
    }

    #[test]
    fn integers() {
        // TODO: test other integer types
        test_i32(-1,
                 "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");
        test_i32(0,
                 "a4e167a76a05add8a8654c169b07b0447a916035aef602df103e8ae0fe2ff390");
        test_u32(10,
                 "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");
        test_u32(1000,
                 "a3346d18105ef801c3598fec426dcc5d4be9d0374da5343f6c8dcbdf24cb8e0b");
    }
}
