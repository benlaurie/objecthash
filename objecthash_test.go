package objecthash

import "bufio"
import "fmt"
import "os"
import "testing"

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
func objectHash(o interface{}) {
	fmt.Printf("%x\n", ObjectHash(o))
}

func ExampleObjectHash_JSON() {
	// Same as equivalent JSON object
	o := []interface{}{`foo`, `bar`}
	objectHash(o)
	// Output: 32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2
}

func ExampleObjectHash_JSON2() {
	// Same as equivalent _Python_ JSON object
	o := []interface{}{`foo`, map[string]interface{}{`bar`: []interface{}{`baz`, nil, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2}}}
	objectHash(o)
	// Same as equivalent Common JSON object
	o = []interface{}{`foo`, map[string]interface{}{`bar`: []interface{}{`baz`, nil, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0}}}
	objectHash(o)
	// Output:
	// 726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
}

func ExampleObjectHash_Set() {
        o := map[string]interface{}{`thing1`: map[string]interface{}{`thing2`: Set{1, 2, `s`}}, `thing3`: 1234.567 }
	objectHash(o)
	// Output: 618cf0582d2e716a70e99c2f3079d74892fec335e3982eb926835967cb0c246c
}

func ExampleObjectHash_ComplexSet() {
	o := Set{`foo`, 23.6, Set{Set{}}, Set{Set{1}}}
	objectHash(o)
	// Output: 3773b0a5283f91243a304d2bb0adb653564573bc5301aa8bb63156266ea5d398
}

func ExampleObjectHash_ComplexSetRepeated() {
	o := Set{`foo`, 23.6, Set{Set{}}, Set{Set{1}}, Set{Set{}}}
	objectHash(o)
	// Output: 3773b0a5283f91243a304d2bb0adb653564573bc5301aa8bb63156266ea5d398
}

func TestGolden(t *testing.T) {
	f, err := os.Open("common_json.test")
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
