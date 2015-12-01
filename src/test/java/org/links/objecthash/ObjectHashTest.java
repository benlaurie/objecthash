package org.links.objecthash;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import java.nio.charset.Charset;
import java.nio.file.Files;
import java.nio.file.FileSystems;
import java.nio.file.Path;
import java.util.Iterator;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.json.JSONException;
import org.junit.Test;

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
        "1b93f704451e1a7a1b8c03626ffcd6dec0bc7ace947ff60d52e1b69b4658ccaa");
    runTest("[1, 2, 3]",
        "157bf16c70bd4c9673ffb5030552df0ee2c40282042ccdf6167850edc9044ab7");
  }

  @Test
  public void test64BitIntegers() throws Exception {
    runTest("[123456789012345]",
        "3488b9bc37cce8223a032760a9d4ef488cdfebddd9e1af0b31fcd1d7006369a4");
    runTest("[123456789012345, 678901234567890]",
        "031ef1aaeccea3bced3a1c6237a4fc00ed4d629c9511922c5a3f4e5c128b0ae4");
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
      } while (line.isEmpty() || line.startsWith("#"));
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
}
