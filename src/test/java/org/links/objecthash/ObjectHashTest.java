package org.links.objecthash;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertTrue;

import org.junit.Test;

public class ObjectHashTest {

  private void runTest(String json, String expectedHash) throws Exception {
    ObjectHash r = ObjectHash.commonJsonHash(json);
    ObjectHash e = ObjectHash.fromHex(expectedHash);
    assertEquals(e, r);
  }

  @Test
  public void testEmptyList() throws Exception {
    runTest("[]",
        "acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0");
  }

  @Test
  public void testListOneString() throws Exception {
    runTest("[\"foo\"]",
        "268bc27d4974d9d576222e4cdbb8f7c6bd6791894098645a19eeca9c102d0964");
  }

  @Test
  public void testListTwoStrings() throws Exception {
    runTest("[\"foo\", \"bar\"]",
        "32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2");
  }

  @Test
  public void testEmptyObject() throws Exception {
    runTest("{}",
        "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4");
  }

  @Test
  public void testListObjectOneStringKeyValue() throws Exception {
    runTest("{\"foo\": \"bar\"}\"",
        "7ef5237c3027d6c58100afadf37796b3d351025cf28038280147d42fdc53b960");
  }

  @Test
  public void testObjectWithListsOfStrings() throws Exception {
    runTest("{\"foo\": [\"bar\", \"baz\"], \"qux\": [\"norf\"]}",
        "f1a9389f27558538a064f3cc250f8686a0cebb85f1cab7f4d4dcc416ceda3c92");

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
