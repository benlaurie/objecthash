package objecthash

import (
	"bufio"
	"fmt"
	"os"
	"testing"
)

const testFile = "../../common_json.test"

func commonJSON(j string) {
	h, err := CommonJSONHash(j)
	if err == nil {
		fmt.Printf("%x\n", h)
	} else {
		fmt.Printf("%v\n", err)
	}
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

func ExampleCommonJSONHash_InvalidJson() {
	commonJSON(`["foo", bar]`)
	// Output:
	// invalid character 'b' looking for beginning of value
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

func printHashOrError(hash [hashLength]byte, err error) {
	if err == nil {
		fmt.Printf("%x\n", hash)
	} else {
		fmt.Printf("%v\n", err)
	}
}

func printObjectHash(o interface{}) {
	printHashOrError(ObjectHash(o))
}

func ExampleObjectHash_JSON() {
	// Same as equivalent JSON object
	o := []interface{}{`foo`, `bar`}
	printObjectHash(o)
	// Also the same
	a := []string{"foo", "bar"}
	aa, err := CommonJSONify(a)
	if err != nil {
		panic(err)
	}
	printObjectHash(aa)
	// Output:
	// 32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2
	// 32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2
}

func ExampleObjectHash_JSON2() {
	// Same as equivalent _Python_ JSON object
	o := []interface{}{`foo`, map[string]interface{}{`bar`: []interface{}{`baz`, nil, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2}}}
	printObjectHash(o)

	// Convert to Common JSON
	oo, err := CommonJSONify(o)
	if err != nil {
		panic(err)
	}
	printObjectHash(oo)

	// Same as equivalent Common JSON object
	o = []interface{}{`foo`, map[string]interface{}{`bar`: []interface{}{`baz`, nil, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0}}}
	printObjectHash(o)

	// Output:
	// 726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
	// 783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213
}

func ExampleObjectHash_JSONStruct() {
	type x struct {
		Foo string
		Bar float64
	}
	a := x{Foo: "abc", Bar: 1.5}
	aa, err := CommonJSONify(a)
	if err != nil {
		panic(err)
	}
	printObjectHash(aa)

	commonJSON(`{"Foo": "abc", "Bar": 1.5}`)
	// Output:
	// edd3ec3058d604abcba6c4944b2a05ca1104cd1911cb78f93732634530f1e003
	// edd3ec3058d604abcba6c4944b2a05ca1104cd1911cb78f93732634530f1e003
}

func ExampleObjectHash_JSONConsideredDangerous() {
	n := 9007199254740992
	nn, err := CommonJSONify(n)
	if err != nil {
		panic(err)
	}
	printObjectHash(nn)
	nn, err = CommonJSONify(n + 1)
	if err != nil {
		panic(err)
	}
	printObjectHash(nn)
	// Output:
	// 9e7d7d02dacab24905c2dc23391bd61d4081a9d541dfafd2469c881cc6c748e4
	// 9e7d7d02dacab24905c2dc23391bd61d4081a9d541dfafd2469c881cc6c748e4
}

func ExampleObjectHash_Set() {
	o := map[string]interface{}{`thing1`: map[string]interface{}{`thing2`: Set{1, 2, `s`}}, `thing3`: 1234.567}
	printObjectHash(o)
	// Output: 618cf0582d2e716a70e99c2f3079d74892fec335e3982eb926835967cb0c246c
}

func ExampleObjectHash_ComplexSet() {
	o := Set{`foo`, 23.6, Set{Set{}}, Set{Set{1}}}
	printObjectHash(o)
	// Output: 3773b0a5283f91243a304d2bb0adb653564573bc5301aa8bb63156266ea5d398
}

func ExampleObjectHash_ComplexSetRepeated() {
	o := Set{`foo`, 23.6, Set{Set{}}, Set{Set{1}}, Set{Set{}}}
	printObjectHash(o)
	// Output: 3773b0a5283f91243a304d2bb0adb653564573bc5301aa8bb63156266ea5d398
}

func ExampleObjectHash_ArraysAndSlices() {
	a1 := [0]bool{}
	printObjectHash(a1)

	s1 := []bool{}
	printObjectHash(s1)

	a2 := [2]string{"Hello", "World!"}
	printObjectHash(a2)

	s2 := []string{"Hello", "World!"}
	printObjectHash(s2)

	a3 := [3]int32{-1, 0, 1}
	printObjectHash(a3)

	s3 := []int32{-1, 0, 1}
	printObjectHash(s3)

	// Output:
	// acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0
	// acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0
	// f68877e4d91514f3216ee7e24a0f271e26977c26f29f7bcb30b1e3e0c1710344
	// f68877e4d91514f3216ee7e24a0f271e26977c26f29f7bcb30b1e3e0c1710344
	// 751293c15d3eacceb5643ac61f9c2f5a597378ef4538de8e7f9188feabf76a81
	// 751293c15d3eacceb5643ac61f9c2f5a597378ef4538de8e7f9188feabf76a81
}

func ExampleObjectHash_ByteBlobs() {
	// Empty byte blobs (arrays & slices) will have different hashes from empty lists.
	ba1 := [0]byte{}
	printObjectHash(ba1)

	bs1 := []byte{}
	printObjectHash(bs1)

	ba2 := [2]byte{255, 255}
	printObjectHash(ba2)

	bs2 := []byte{255, 255}
	printObjectHash(bs2)

	ba3 := [3]byte{0, 0, 0}
	printObjectHash(ba3)

	bs3 := []byte{0, 0, 0}
	printObjectHash(bs3)

	// byte is a type alias for uint8 and therefore they're indistinguishable at
	// runtime. This means that uint8 arrays will hash the same way as byte
	// arrays.
	ui3 := []uint8{0, 0, 0}
	printObjectHash(ui3)

	// Output:
	// 454349e422f05297191ead13e21d3db520e5abef52055e4964b82fb213f593a1
	// 454349e422f05297191ead13e21d3db520e5abef52055e4964b82fb213f593a1
	// 43ad246c14bf0bc0b2ac9cab9fae202a181ab4c6abb07fb40cad8c67a4cab8ee
	// 43ad246c14bf0bc0b2ac9cab9fae202a181ab4c6abb07fb40cad8c67a4cab8ee
	// d877bf4e5023a6df5262218800a7162e240c84e44696bb2c3ad1c5e756f3dac1
	// d877bf4e5023a6df5262218800a7162e240c84e44696bb2c3ad1c5e756f3dac1
	// d877bf4e5023a6df5262218800a7162e240c84e44696bb2c3ad1c5e756f3dac1
}

func ExampleObjectHash_Maps() {
	m1 := map[string]bool{}
	printObjectHash(m1)

	m2 := map[int64]string{-1: "Hello", 0: "World!"}
	printObjectHash(m2)

	m3 := map[bool]int32{true: 1, false: 0}
	printObjectHash(m3)
	// Output:
	// 18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4
	// 1909a37b5f94b2b7760fc5f5a76eee66a8907e71ba3281831927c19dfe8c1801
	// 1eb24844c2bb924515efd56f3310d875a3aeaef54d690186d698bfd926a93322
}

func ExampleObjectHash_UnsupportedType() {
	f := func() {}
	printObjectHash(f)
	// Output:
	// Unsupported type: func()
}

func ExampleHashBytes_CalledWithIncorrectTypes() {
	var v1 bool = true
	printHashOrError(hashBytes(v1))

	v2 := []int32{0, 1, 2}
	printHashOrError(hashBytes(v2))

	v3 := [2]uint32{3, 4}
	printHashOrError(hashBytes(v3))

	// Output:
	// Assertion error: Expected a byte slice or a bytes array. Instead got type bool
	// Assertion error: Expected a byte slice or a bytes array. Instead got type []int32
	// Assertion error: Expected a byte slice or a bytes array. Instead got type [2]uint32
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

		cjh, err := CommonJSONHash(j)
		if err != nil {
			t.Error(err)
		}

		hh := fmt.Sprintf("%x", cjh)
		if h != hh {
			t.Errorf("Got %s expected %s", hh, h)
		}
	}
}
