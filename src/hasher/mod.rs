#[cfg(feature = "objecthash-ring")]
pub mod ring;

// TODO: Use std::hash::BuildHasherDefault or our own similar version
#[cfg(feature = "objecthash-ring")]
pub fn default() -> ring::Hasher {
    ring::Hasher::default()
}
