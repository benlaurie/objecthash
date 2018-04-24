package org.links.objecthash;

import org.json.JSONException;
import org.json.JSONTokener;

import java.security.NoSuchAlgorithmException;

// TODO: should just extend ObjectHash probably
public class Redacted extends ObjectHash {
    static final String PREFIX = "**REDACTED**";

    protected Redacted(byte[] hash) throws NoSuchAlgorithmException {
        super();
        this.hash = hash;
    }

    public static Redacted fromString(String repesentation) throws NoSuchAlgorithmException {
        ObjectHash underlyingHash = ObjectHash.fromHex(repesentation.replace(PREFIX, ""));
        return new Redacted(underlyingHash.hash());
    }

    @Override
    public String toString() {
        return String.format("%s%s", PREFIX, super.toString());
    }

    public static Redacted pythonJsonHash(String json) throws NoSuchAlgorithmException, JSONException {
        ObjectHash h = ObjectHash.pythonJsonHash(json);
        return new Redacted(h.hash());
    }

}
