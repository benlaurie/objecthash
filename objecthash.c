#include <assert.h>
#include <json-c/json.h>
#include <stdio.h>
#include <string.h>

#include "objecthash.h"

bool object_hash(/*const*/ json_object *j, byte hash[HASH_SIZE]);

static void hash_init(hash_ctx * const c) {
  sha256_init(c);
}

static void hash_update(hash_ctx * const c, const byte * const b,
			const size_t l) {
  sha256_update(c, b, l);
}

static void hash_final(hash_ctx * const c, hash h) {
  sha256_final(c, h);
}

static void hash_bytes(const byte t, const byte * const b, const size_t l,
		       hash hash) {
  hash_ctx ctx;
  hash_init(&ctx);

  byte tt[1];
  tt[0] = t;

  hash_update(&ctx, tt, sizeof tt);
  hash_update(&ctx, b, l);

  hash_final(&ctx, hash);
}

/*
static void print_json_value(json_object *jobj) {
  enum json_type type;
  type = json_object_get_type(jobj);
  printf("type: %d",type);
  switch (type) {
  case json_type_boolean: printf("json_type_boolean\n");
    printf("value: %s\n", json_object_get_boolean(jobj)? "true": "false");
    break;
  case json_type_double: printf("json_type_double\n");
    printf("          value: %lf\n", json_object_get_double(jobj));
    break;
  case json_type_int: printf("json_type_int\n");
    printf("          value: %d\n", json_object_get_int(jobj));
    break;
  case json_type_string: printf("json_type_string\n");
    printf("          value: %s\n", json_object_get_string(jobj));
    break;
  default:
    printf("oops");
  }
}
*/

static int dict_comp(const void *a, const void *b) {
  return memcmp(a, b, 2 * sizeof(hash));
}

bool object_hash_str(const char *str, size_t len, byte hash[HASH_SIZE]) {
  hash_bytes('u', (const byte *)str, len, hash);
  return true;
}

static bool object_hash_dict(/*const*/ json_object * const d, hash h) {
  // FIXME: there may be a better way
  size_t len = 0;
  {
    json_object_object_foreach(d, key, val) {
      ++len;
    }
  }
  byte *hashes = alloca(2 * len * sizeof(hash));
  
  size_t n = 0;
  json_object_object_foreach(d, key, val) {
    object_hash_str(key, strlen(key), &hashes[2 * n * sizeof(hash)]);
    object_hash(val, &hashes[(2 * n + 1) * sizeof(hash)]);
    ++n;
  }
  
  qsort(hashes, len, 2 * sizeof(hash), dict_comp);
  hash_bytes('d', hashes, 2 * len * sizeof(hash), h);
  return true;
}

static bool object_hash_int(int64_t i, hash h) {
  char buf[100];

  sprintf(buf, "%ld", i);
  hash_bytes('i', (byte *)buf, strlen(buf), h);
  return true;
}

static void float_normalize(double f, char out[1000]) {
  const char * const base = out;
  
  // special case 0
  // Note that if we allowed f to end up > .5 or == 0, we'd get the same thing
  if (f == 0.0) {
    strcpy(out, "+0:");
    return;
  }
  
  // sign
  *out = '+';
  if (f < 0) {
    *out = '-';
    f = -f;
  }
  ++out;
  
  // exponent
  int e = 0;
  while (f > 1) {
    f /= 2;
    e += 1;
  }
  while (f <= .5) {
    f *= 2;
    e -= 1;
  }
  out += sprintf(out, "%d:", e);

  // mantissa
  assert(f <= 1);
  assert(f > .5);
  while (f != 0) {
    if (f >= 1) {
      *out++ = '1';
      f -= 1;
    } else {
      *out++ = '0';
    }
    assert (f < 1);
    assert (out - base < 1000);
    f *= 2;
  }

  *out = '\0';
}

static bool object_hash_float(const double d, hash h) {
  char buf[1000];

  float_normalize(d, buf);
//  printf("%f: %s\n", d, buf);
  hash_bytes('f', (byte *)buf, strlen(buf), h);
  return true;
}

bool object_hash_list(json_object *l, hash h) {
  hash_ctx ctx;
  hash_init(&ctx);

  byte c[1];
  c[0] = 'l';
  hash_update(&ctx, c, 1);
  
  int len = json_object_array_length(l);
  for (int n = 0; n < len; ++n) {
    byte ihash[HASH_SIZE];
    if (!object_hash(json_object_array_get_idx(l, n), ihash))
      return false;
    hash_update(&ctx, ihash, sizeof ihash);
  }

  hash_final(&ctx, h);
  return true;
}

bool object_hash(/*const*/ json_object *j, byte hash[HASH_SIZE]) {
  enum json_type type;
  type = json_object_get_type(j);
  switch (type) {
  case json_type_boolean:
    assert(false);
  case json_type_double:
    return object_hash_float(json_object_get_double(j), hash);
  case json_type_int:
    return object_hash_int(json_object_get_int64(j), hash);
  case json_type_string: {
    const char *s = json_object_get_string(j);
    return object_hash_str(s, strlen(s), hash);
  }
  case json_type_object:
    return object_hash_dict(j, hash);
  case json_type_array:
    return object_hash_list(j, hash);
  case json_type_null:
    hash_bytes('n', NULL, 0, hash);
    return true;
  default:
    break;
  }
  printf("type = %d\n", type);
  assert(false);
  return false;
}

bool python_json_hash(const char * const json, hash hash) {
    json_object * const j = json_tokener_parse(json);
    return object_hash(j, hash);
}
