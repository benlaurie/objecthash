package org.links.objecthash;

import java.security.NoSuchAlgorithmException;

// TODO: should just extend ObjectHash probably
public class Redacted {
  static final String PREFIX = "**REDACTED**";
  private ObjectHash hash;

  public Redacted(ObjectHash hash) {
    this.hash = hash;
  }

  public static Redacted fromString(String repesentation) throws NoSuchAlgorithmException {
    return new Redacted(ObjectHash.fromHex(repesentation.replace(PREFIX, "")));
  }

  public byte[] hash() {
    return this.hash.hash();
  }

  @Override
  public String toString() {
    return String.format("%s%s", PREFIX, hash.toString());
  }
}
