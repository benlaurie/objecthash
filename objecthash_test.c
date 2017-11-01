#include "objecthash.h"

#include <assert.h>
#include <string.h>
#include <stdio.h>

#define UNUSED(x) ((void)x)

static void a_to_hash(const char *in, hash out) {
  for (int n = 0; n < HASH_SIZE; ++n)
    sscanf(&in[n * 2], "%2hhx", &out[n]);
}

static void hexdump(const byte *b, size_t l) {
  while(l--)
    printf("%02x", *b++);
}

static void check_hash(const hash h1, const hash h2) {
  if (memcmp(h1, h2, HASH_SIZE) != 0) {
    puts("hashes don't match:");
    hexdump(h1, HASH_SIZE);
    putchar(' ');
    hexdump(h2, HASH_SIZE);
    putchar('\n');
    assert(false);
  }
}

static void run_test(const char * const json, const char * const h) {
  hash r;
  common_json_hash(json, r);

  hash e;
  a_to_hash(h, e);

  check_hash(e, r);
}

static void run_py_test(const char * const json, const char * const h) {
  hash r;
  python_json_hash(json, r);

  hash e;
  a_to_hash(h, e);

  check_hash(e, r);
}

int main(int argc, char **argv) {
  UNUSED(argc);
  UNUSED(argv);
  FILE *f = fopen("common_json.test", "r");
  assert(f);
  for (;;) {
    char json[1024];
    const char *r;
    for (;;) {
      r = fgets(json, sizeof json, f);
      if (r == NULL || (r[0] != '\n' && r[0] != '#'))
	break;
    }
    if (r == NULL)
      break;
    size_t jl = strlen(json);
    assert(jl > 0 && json[jl - 1] == '\n');
    char h[2 * HASH_SIZE + 2];  // hash in hex, \n, \0
    assert(fgets(h, sizeof h, f) != NULL);
    assert(strlen(h) == 2 * HASH_SIZE + 1);
    assert(h[2 * HASH_SIZE] == '\n');
    run_test(json, h);
  }
  run_py_test("[\"foo\", {\"bar\": [\"baz\", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]",
	      "783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213");
  run_py_test("[\"foo\", {\"bar\": [\"baz\", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]",
	      "726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a");

  puts("all tests passed");
  return 0;
}
