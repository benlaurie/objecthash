#[macro_export]
macro_rules! objecthash_member {
    ($key:expr => $value:expr) => {
        {
            let key_digest = $crate::digest($key);
            let value_digest = $crate::digest($value);
            let mut result = Vec::with_capacity(key_digest.as_ref().len() + value_digest.as_ref().len());

            result.extend_from_slice(key_digest.as_ref());
            result.extend_from_slice(value_digest.as_ref());
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
                digests.push(objecthash_member!($key => $value));
            )+

            digests.sort();

            $hasher.update($crate::types::DICT_TAG);
            for value in &digests {
                $hasher.update(&value);
            }
        }
     };
);

#[cfg(test)]
#[cfg(feature = "objecthash-ring")]
mod tests {
    use {hasher, ObjectHasher};
    use rustc_serialize::hex::ToHex;

    #[test]
    fn objecthash_struct_test() {
        let mut h = hasher::default();

        objecthash_struct!(h, "foo" => &1);

        assert_eq!(
            h.finish().as_ref().to_hex(),
            "bf4c58f5e308e31e2cd64bdbf7a01b9b595a13602438be5e912c7d94f6d8177a"
        );
    }
}
