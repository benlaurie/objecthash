package org.links.objecthash;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import org.json.JSONException;
import org.junit.Test;

public class ObjectHashTest {

  private void runTest(String json, String expectedHash) throws Exception {
    ObjectHash r = ObjectHash.pythonJsonHash(json);
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

  @Test
  public void testNull() throws Exception {
    runTest("[null]",
        "5fb858ed3ef4275e64c2d5c44b77534181f7722b7765288e76924ce2f9f7f7db");
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
  public void testBoolean() throws Exception {
    runTest("true",
        "7dc96f776c8423e57a2785489a3f9c43fb6e756876d6ad9a9cac4aa4e72ec193");
    runTest("false",
        "c02c0b965e023abee808f2b548d8d5193a8b5229be6f3121a6f16e2d41a449b3");
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
