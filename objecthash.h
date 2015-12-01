#include <stdbool.h>
#include <openssl/sha.h>

#ifdef __cplusplus
extern "C" {
#endif


typedef unsigned char byte;

static const int HASH_SIZE = SHA256_DIGEST_LENGTH;

typedef byte hash[HASH_SIZE];
typedef SHA256_CTX hash_ctx;

bool common_json_hash(const char *json, hash h);

#ifdef __cplusplus
}  // extern "C"
#endif
