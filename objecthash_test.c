#include "objecthash.h"

#include <assert.h>
#include <string.h>
#include <stdio.h>

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
  python_json_hash(json, r);
  
  hash e;
  a_to_hash(h, e);

  check_hash(e, r);
}

int main(int argc, char **argv) {
  run_test("[]",
     "acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0");
  run_test("[\"foo\"]",
     "268bc27d4974d9d576222e4cdbb8f7c6bd6791894098645a19eeca9c102d0964");
  run_test("[\"foo\", \"bar\"]",
	   "32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2");
  run_test("{}",
     "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4");
  run_test("{\"foo\": \"bar\"}",
     "7ef5237c3027d6c58100afadf37796b3d351025cf28038280147d42fdc53b960");
  run_test("{\"foo\": [\"bar\", \"baz\"], \"qux\": [\"norf\"]}",
     "f1a9389f27558538a064f3cc250f8686a0cebb85f1cab7f4d4dcc416ceda3c92");
  run_test("[\"foo\", {\"bar\": [\"baz\", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]",
	   "783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213");
  run_test("[\"foo\", {\"bar\": [\"baz\", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]",
	   "726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a");
  
  puts("all tests passed");
  return 0;
}
