#include "crypto-algorithms/sha256.h"

typedef unsigned char byte;
typedef int bool;

static const int true = 1;
static const int false = 0;
static const int HASH_SIZE = SHA256_BLOCK_SIZE;

typedef byte hash[HASH_SIZE];
typedef SHA256_CTX hash_ctx;

bool common_json_hash(const char *json, hash h);
bool python_json_hash(const char * const json, hash hash);
