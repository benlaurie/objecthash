package objecthash

import "bufio"
import "fmt"
import "os"
import "testing"

const testFile = "../../common_json.test"

func commonJSON(j string) {
	fmt.Printf("%x\n", CommonJSONHash(j))
}

func ExampleCommonJSONHash_Common() {
	commonJSON(`["foo", "bar"]`)
	// Output: 32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2
}

func ExampleCommonJSONHash_FloatAndInt() {
	commonJSON(`["foo", {"bar":["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]`)
	// Integers and floats are the same in common JSON
	commonJSON(`["foo", {"bar":["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]`)
	// Output:
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
}

func ExampleCommonJSONHash_KeyChange() {
	commonJSON(`["foo", {"b4r":["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]`)
	// Output: 7e01f8b45da35386e4f9531ff1678147a215b8d2b1d047e690fd9ade6151e431
}

func ExampleCommonJSONHash_KeyOrderIndependence() {
	commonJSON(`{"k1":"v1","k2":"v2","k3":"v3"}`)
	commonJSON(`{"k2":"v2","k1":"v1","k3":"v3"}`)
	// Output:
	// ddd65f1f7568269a30df7cafc26044537dc2f02a1a0d830da61762fc3e687057
	// ddd65f1f7568269a30df7cafc26044537dc2f02a1a0d830da61762fc3e687057
}

/*
func ExampleCommonJSONHash_UnicodeNormalisation() {
	commonJSON("\"\u03d3\"")
	commonJSON("\"\u03d2\u0301\"")
	// Output:
	// f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d
	// f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d
}
*/
func getObjectHash(o interface{}) {
	fmt.Printf("%x\n", ObjectHash(o))
}

func ExampleObjectHash_JSON() {
	// Same as equivalent JSON object
	o := []interface{}{`foo`, `bar`}
	getObjectHash(o)
	// Output: 32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2
}

func ExampleObjectHash_JSON2() {
	// Same as equivalent _Python_ JSON object
	o := []interface{}{`foo`, map[string]interface{}{`bar`: []interface{}{`baz`, nil, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2}}}
	getObjectHash(o)
	// Same as equivalent Common JSON object
	o = []interface{}{`foo`, map[string]interface{}{`bar`: []interface{}{`baz`, nil, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0}}}
	getObjectHash(o)
	// Output:
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
}

func ExampleObjectHash_Set() {
	o := map[string]interface{}{`thing1`: map[string]interface{}{`thing2`: Set{1, 2, `s`}}, `thing3`: 1234.567}
	getObjectHash(o)
	// Same as when using floats instead of integers.
	o = map[string]interface{}{`thing1`: map[string]interface{}{`thing2`: Set{1.0, 2.0, `s`}}, `thing3`: 1234.567}
	getObjectHash(o)
	// Output:
	// 573b37091d5e1642f8a33517147a9e2e60b01689d7d3c688e001d288ba3a5228
	// 573b37091d5e1642f8a33517147a9e2e60b01689d7d3c688e001d288ba3a5228
}

func ExampleObjectHash_ComplexSet() {
	o := Set{`foo`, 23.6, Set{Set{}}, Set{Set{1}}}
	getObjectHash(o)
	// Same as when using floats instead of integers.
	o = Set{`foo`, 23.6, Set{Set{}}, Set{Set{1.0}}}
	getObjectHash(o)
	// Output:
	// d60f36a67688b9137b5463adee3f4d15339eb8f3e1f02f81eccf8b113408d0fd
	// d60f36a67688b9137b5463adee3f4d15339eb8f3e1f02f81eccf8b113408d0fd
}

func ExampleObjectHash_ComplexSetRepeated() {
	o := Set{`foo`, 23.6, Set{Set{}}, Set{Set{1}}, Set{Set{}}}
	getObjectHash(o)
	// Same as when using floats instead of integers.
	o = Set{`foo`, 23.6, Set{Set{}}, Set{Set{1.0}}, Set{Set{}}}
	getObjectHash(o)
	// Output:
	// 55885cc37fea864170a2d8874a537fdd2a0be932f2f23df0bedf72642fe3bd78
	// 55885cc37fea864170a2d8874a537fdd2a0be932f2f23df0bedf72642fe3bd78
}

func TestGolden(t *testing.T) {
	f, err := os.Open(testFile)
	if err != nil {
		t.Error(err)
		return
	}
	defer f.Close()
	s := bufio.NewScanner(f)
	for {
		var j string
		for {
			if !s.Scan() {
				return
			}
			j = s.Text()
			if len(j) != 0 && j[0] != '#' {
				break
			}
		}
		if !s.Scan() {
			t.Error("Premature EOF")
			return
		}
		h := s.Text()
		hh := fmt.Sprintf("%x", CommonJSONHash(j))
		if h != hh {
			t.Errorf("Got %s expected %s", hh, h)
		}
	}
}
