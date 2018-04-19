package org.links.objecthash;

import org.json.JSONException;
import org.junit.Test;

import java.nio.charset.Charset;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.security.NoSuchAlgorithmException;
import java.text.MessageFormat;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Logger;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

public class ObjectHashTest {
  private static final Logger LOG = Logger.getLogger(ObjectHashTest.class.getName());
  private static final String GOLDEN_JSON_FILENAME = "common_json.test";

  private void runTest(String json, String expectedHash) throws Exception {
    ObjectHash r = ObjectHash.pythonJsonHash(json);
    ObjectHash e = ObjectHash.fromHex(expectedHash);
    assertEquals(e, r);
  }

  @Test
  public void test32BitIntegers() throws Exception {
    runTest("[123]",
        "2e72db006266ed9cdaa353aa22b9213e8a3c69c838349437c06896b1b34cee36");
    runTest("[1, 2, 3]",
        "925d474ac71f6e8cb35dd951d123944f7cabc5cda9a043cf38cd638cc0158db0");
  }

  @Test
  public void test64BitIntegers() throws Exception {
    runTest("[123456789012345]",
        "f446de5475e2f24c0a2b0cd87350927f0a2870d1bb9cbaa794e789806e4c0836");
    runTest("[123456789012345, 678901234567890]",
        "d4cca471f1c68f62fbc815b88effa7e52e79d110419a7c64c1ebb107b07f7f56");
  }

  @Test
  public void testGolden() throws Exception {
    List<String> lines = Files.readAllLines(
        FileSystems.getDefault().getPath(GOLDEN_JSON_FILENAME),
        Charset.forName("UTF-8"));
    Iterator<String> iter = lines.iterator();
    while (iter.hasNext()) {
      String line;
      do {
        line = iter.next();
      } while (line.isEmpty() || line.startsWith("#") || line.startsWith("~#"));
      String json = line;
      if (!iter.hasNext()) break;
      String hash = iter.next();
      runTest(json, hash);
    }
  }

  @Test
  public void testFloatNormalization() throws Exception {
    Double[] testValues = {
        1.0, 1.5, 2.0, 1000.0, 0.0001, -23.1234
    };
    String[] expectedNormalizations = {
        "+0:1", "+1:011", "+1:1", "+10:01111101",
        "+-13:011010001101101110001011101011000111000100001100101101",
        "-5:010111000111111001011100100100011101000101001110001111"
    };
    assertEquals(testValues.length, expectedNormalizations.length);
    for (int idx = 0; idx < testValues.length; ++idx) {
      assertEquals(expectedNormalizations[idx],
                   ObjectHash.normalizeFloat(testValues[idx]));
    }
  }

  private final static String[] BAD_JSONS = { "", "[", "]", "{", "}" };

  @Test
  public void testIllegalJSONs() throws Exception {
    for (String badJson : BAD_JSONS) {
      try {
        runTest(badJson, "deadbeef");
        fail("JSONException was expected for input \"" + badJson + "\"");
      } catch (JSONException e) {
        // expected
      } catch (Exception e) {
        fail("Caught " + e + " but wanted JSONException");
      }
    }
  }

  private final static String[][] HEXVALUES = {
      {"",           "0000000000000000000000000000000000000000000000000000000000000000"},
      {"123",        "0000000000000000000000000000000000000000000000000000000000000123"},
      {"abc123",     "0000000000000000000000000000000000000000000000000000000000abc123"},
      {"0123456789", "0000000000000000000000000000000000000000000000000000000123456789"},
      {"111122223333444455556666777788889999AAAABBBBCCCCDDDDEEEEFFFF0000",
          "111122223333444455556666777788889999aaaabbbbccccddddeeeeffff0000"}
  };

  @Test
  public void toHexFromHexRoundtrips() throws Exception {
    for (String[] hexPair : HEXVALUES) {
      assertEquals(hexPair[1], ObjectHash.fromHex(hexPair[0]).toHex());
    }
  }

  @Test
  public void testHashRedaction() throws JSONException, NoSuchAlgorithmException {
    String jsonPart = "{\"field1\": \"value\", \"field2\": \"value2\"}";

    ObjectHash partHash = ObjectHash.pythonJsonHash(jsonPart);

    String jsonFull = MessageFormat.format("'{'\"field3\": \"value3\", \"part\": {0}'}'", jsonPart);
    String jsonFullWithRedacted = MessageFormat.format("'{'\"field3\": \"value3\", \"part\": {0}'}'", new Redacted(partHash));

    assertTrue(jsonFullWithRedacted.contains(partHash.toString()));

    ObjectHash fullHash = ObjectHash.pythonJsonHash(jsonFull);
    ObjectHash fullWithRedactedHash = ObjectHash.pythonJsonHash(jsonFullWithRedacted);

    assertEquals(fullHash, fullWithRedactedHash);
  }



}
