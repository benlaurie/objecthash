use {ObjectHash, ObjectHasher};

use unicode_normalization::UnicodeNormalization;

const INTEGER_TAG: &'static [u8; 1] = b"i";
const STRING_TAG: &'static [u8; 1] = b"u";
const LIST_TAG: &'static [u8; 1] = b"l";

#[cfg(feature = "octet-strings")]
const OCTET_TAG: &'static [u8; 1] = b"o";

macro_rules! objecthash_digest {
    ($hasher:expr, $tag:expr, $bytes:expr) => {
        $hasher.update($tag);
        $hasher.update($bytes);
    };
}

impl<T: ObjectHash> ObjectHash for Vec<T> {
    #[inline]
    fn objecthash<H: ObjectHasher>(&self, hasher: &mut H) {
        hasher.update(LIST_TAG);

        for value in self {
            hasher.update_nested(|h| value.objecthash(h));
        }
    }
}

impl ObjectHash for str {
    #[inline]
    fn objecthash<H: ObjectHasher>(&self, hasher: &mut H) {
        let normalized = self.nfc().collect::<String>();
        objecthash_digest!(hasher, STRING_TAG, normalized.as_bytes());
    }
}

// Technically ObjectHash does not define a representation for binary data
// For now this is a non-standard extension of ObjectHash
#[cfg(feature = "octet-strings")]
impl ObjectHash for [u8] {
    #[inline]
    fn objecthash<H: ObjectHasher>(&self, hasher: &mut H) {
        objecthash_digest!(hasher, OCTET_TAG, self);
    }
}

macro_rules! impl_inttype (($inttype:ident) => (
    impl ObjectHash for $inttype {
        #[inline]
        fn objecthash<H: ObjectHasher>(&self, hasher: &mut H) {
            objecthash_digest!(hasher, INTEGER_TAG, self.to_string().as_bytes());
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
    use {hasher, ObjectHash, ObjectHasher};
    use rustc_serialize::hex::ToHex;

    macro_rules! h {
       ($value:expr) => {
            {
                let mut hasher = hasher::default();
                $value.objecthash(&mut hasher);
                hasher.finish().as_ref().to_hex()
            }
        };
    }

    #[test]
    fn integers() {
        assert_eq!(h!(-1), "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");
        assert_eq!(h!(0), "a4e167a76a05add8a8654c169b07b0447a916035aef602df103e8ae0fe2ff390");
        assert_eq!(h!(10), "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");
        assert_eq!(h!(1000), "a3346d18105ef801c3598fec426dcc5d4be9d0374da5343f6c8dcbdf24cb8e0b");

        assert_eq!(h!(-1 as i8), "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");
        assert_eq!(h!(-1 as i16), "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");
        assert_eq!(h!(-1 as i32), "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");
        assert_eq!(h!(-1 as i64), "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");
        assert_eq!(h!(-1 as isize), "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e");

        assert_eq!(h!(10 as u8), "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");
        assert_eq!(h!(10 as u16), "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");
        assert_eq!(h!(10 as u32), "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");
        assert_eq!(h!(10 as u64), "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");
        assert_eq!(h!(10 as usize), "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce");

    }

    #[test]
    fn strings() {
        let u1n = "\u{03D3}";
        let u1d = "\u{03D2}\u{0301}";

        let digest = "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d";
        assert_eq!(h!(u1n), digest);
        assert_eq!(h!(&u1d), digest);

        assert_eq!(h!("ԱԲաբ"), "2a2a4485a4e338d8df683971956b1090d2f5d33955a81ecaad1a75125f7a316c");
    }

    #[test]
    fn vectors() {
        assert_eq!(h!(vec![123]), "1b93f704451e1a7a1b8c03626ffcd6dec0bc7ace947ff60d52e1b69b4658ccaa");
        assert_eq!(h!(vec![1, 2, 3]), "157bf16c70bd4c9673ffb5030552df0ee2c40282042ccdf6167850edc9044ab7");
        assert_eq!(h!(vec![123456789012345u64]), "3488b9bc37cce8223a032760a9d4ef488cdfebddd9e1af0b31fcd1d7006369a4");
        assert_eq!(h!(vec![123456789012345u64, 678901234567890u64]), "031ef1aaeccea3bced3a1c6237a4fc00ed4d629c9511922c5a3f4e5c128b0ae4");
    }
}
