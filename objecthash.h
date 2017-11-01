#include <openssl/sha.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef unsigned char byte;

#define HASH_SIZE SHA256_DIGEST_LENGTH

typedef byte hash[HASH_SIZE];
typedef SHA256_CTX hash_ctx;

bool python_json_hash(const char *json, hash h);
bool common_json_hash(const char *json, hash h);

#ifdef __cplusplus
}  // extern "C"
#endif
