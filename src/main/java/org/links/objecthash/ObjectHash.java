package org.links.objecthash;

import java.nio.ByteBuffer;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Iterator;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONTokener;

/**
 * TODO(phad): docs.
 */
public class ObjectHash implements Comparable<ObjectHash> {
  private static final int SHA256_BLOCK_SIZE = 32;
  private static final String SHA256 = "SHA-256";

  private byte[] hash;
  private MessageDigest digester;

  private enum JsonType {
    BOOLEAN,
    ARRAY,
    OBJECT,
    INT,
    FLOAT,
    STRING,
    NULL,
    UNKNOWN
  }

  private ObjectHash() throws NoSuchAlgorithmException {
    this.hash = new byte[SHA256_BLOCK_SIZE];
    this.digester = MessageDigest.getInstance(SHA256);
  }

  private void hashAny(Object obj) throws NoSuchAlgorithmException,
                                          JSONException {
    digester.reset();
    JsonType outerType = getType(obj);
    switch (outerType) {
      case ARRAY: {
        hashList((JSONArray) obj);
        break;
      }
      case OBJECT: {
        hashObject((JSONObject) obj);
        break;
      }
      case STRING: {
        hashString((String) obj);
        break;
      }
      // TODO(phad): types BOOLEAN, INT, FLOAT, NULL
      default: {
        throw new IllegalArgumentException("Illegal type in JSON: "
                                           + obj.getClass());
      }
    }

  }

  private void hashTaggedBytes(char tag, byte[] bytes)
      throws NoSuchAlgorithmException {
    digester.reset();
    digester.update((byte) tag);
    digester.update(bytes);
    hash = digester.digest();
  }

  private void hashString(String str) throws NoSuchAlgorithmException {
    hashTaggedBytes('u', str.getBytes());
  }


  private void hashList(JSONArray list) throws NoSuchAlgorithmException,
                                               JSONException {
    digester.reset();
    digester.update((byte) ('l'));
    for (int n = 0; n < list.length(); ++n) {
      ObjectHash innerObject = new ObjectHash();
      innerObject.hashAny(list.get(n));
      digester.update(innerObject.hash());
    }
    hash = digester.digest();
  }

  private void hashObject(JSONObject obj) throws NoSuchAlgorithmException, 
                                                 JSONException {
    ByteBuffer buff = ByteBuffer.allocate(2 * obj.length() * SHA256_BLOCK_SIZE);
    Iterator<String> keys = obj.keys();
    while (keys.hasNext()) {
      String key = keys.next();
      // TODO(phad): would be nice to chain all these calls builder-stylee.
      ObjectHash hKey = new ObjectHash();
      hKey.hashString(key);
      ObjectHash hVal = new ObjectHash();
      hVal.hashAny(obj.get(key));
      buff.put(hKey.hash());
      buff.put(hVal.hash());
    }
    hashTaggedBytes('d', buff.array());
  }

  private static int parseHex(char digit) {
    assert ((digit >= '0' && digit <= '9') || (digit >= 'a' && digit <= 'f'));
    if (digit >= '0' && digit <= '9') {
      return digit - '0';
    } else {
      return 10 + digit - 'a';
    }
  }

  public static ObjectHash fromHex(String hex) throws NoSuchAlgorithmException {
    ObjectHash h = new ObjectHash();
    hex = hex.toLowerCase();
    if (hex.length() % 2 == 1) {
      hex = '0' + hex;
    }
    // TODO(phad): maybe just use Int.valueOf(s).intValue()
    int pos = SHA256_BLOCK_SIZE;
    for (int idx = hex.length(); idx > 0; idx -= 2) {
      h.hash[--pos] = (byte) (16 * parseHex(hex.charAt(idx - 2))
                              + parseHex(hex.charAt(idx - 1)));
    }
    return h;
  }

  private static JsonType getType(Object jsonObj) {
    if (jsonObj instanceof JSONArray) {
      return JsonType.ARRAY;
    } else if (jsonObj instanceof JSONObject) {
      return JsonType.OBJECT;
    } else if (jsonObj instanceof String) {
      return JsonType.STRING;
    } else {
      return JsonType.UNKNOWN;
    }
  }

  public static ObjectHash commonJsonHash(String json)
      throws JSONException, NoSuchAlgorithmException {
    ObjectHash h = new ObjectHash();
    JSONTokener tokener = new JSONTokener(json);
    Object outerValue = tokener.nextValue();
    JsonType outerType = getType(outerValue);
    switch (outerType) {
      case ARRAY: {
        h.hashList((JSONArray) outerValue);
        break;
      }
      case OBJECT: {
        h.hashObject((JSONObject) outerValue);
        break;
      }
      default: {
        throw new IllegalArgumentException("Illegal outer type in JSON: "
                                           + outerType);
      }
    }
    return h;
  }

  public static ObjectHash pythonJsonHash(String json)
      throws JSONException, NoSuchAlgorithmException {
    // TODO(phad): this.
    return new ObjectHash();
  }

  @Override
  public String toString() {
    return this.toHex();
  }

  @Override
  public boolean equals(Object other) {
   if (this == other) return true;
   if (other == null) return false;
   if (this.getClass() != other.getClass()) return false;
   return this.toHex().equals(((ObjectHash) other).toHex());
  }

  @Override
  public int compareTo(ObjectHash other) {
    return toHex().compareTo(other.toHex());
  }

  public byte[] hash() {
    return hash;
  }

  public String toHex() {
    StringBuffer hexString = new StringBuffer();
    for (int idx = 0; idx < hash.length; ++idx) {
      String hex = Integer.toHexString(0xff & hash[idx]);
      if (hex.length() == 1) {
        hexString.append('0');
      }
      hexString.append(hex);
    }
    return hexString.toString();
  }
}
