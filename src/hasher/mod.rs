#[cfg(feature = "objecthash-ring")]
pub mod ring;

#[cfg(feature = "objecthash-ring")]
pub fn default() -> ring::Hasher {
    ring::Hasher::new()
}
