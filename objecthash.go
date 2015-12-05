package objecthash

import "bytes"
import "crypto/sha256"
import "encoding/json"
import "fmt"
import "sort"

//import "golang.org/x/text/unicode/norm"

const hashLength int = sha256.Size

func hash(t string, b []byte) [hashLength]byte {
	//fmt.Printf("%x %x\n", []byte(t), b)
	h := sha256.New()
	h.Write([]byte(t))
	h.Write(b)
	// FIXME: Seriously, WTF?
	var r []byte
	r = h.Sum(r)
	var rr [hashLength]byte
	copy(rr[:], r)
	//fmt.Printf("= %x\n", rr)
	return rr;
}

// FIXME: if What You Hash Is What You Get, then this needs to be safe
// to use as a set.
// Note: not actually safe to use as a set
type Set []interface{}

type sortableHashes [][hashLength]byte
func (h sortableHashes) Len() int { return len(h) }
func (h sortableHashes) Swap(i, j int) { h[i], h[j] = h[j], h[i] }
func (h sortableHashes) Less(i, j int) bool { return bytes.Compare(h[i][:], h[j][:]) < 0 }

func hashSet(s Set) [hashLength]byte {
	h := make([][hashLength]byte, len(s))
	for n, e := range s {
		h[n] = ObjectHash(e)
	}
	sort.Sort(sortableHashes(h))
	b := new(bytes.Buffer)
	var prev [hashLength]byte
	for _, hh := range h {
		if hh != prev {
			b.Write(hh[:])
		}
		prev = hh
	}
	return hash(`s`, b.Bytes())
}

func hashList(l []interface{}) [hashLength]byte {
	h := new(bytes.Buffer)
	for _, o := range l {
		b := ObjectHash(o)
		h.Write(b[:])
	}
	return hash(`l`, h.Bytes())
}

func hashUnicode(s string) [hashLength]byte {
	//return hash(`u`, norm.NFC.Bytes([]byte(s)))
	return hash(`u`, []byte(s))
}

type hashEntry struct {
	khash [hashLength]byte
	vhash [hashLength]byte
}
type byKHash []hashEntry
func (h byKHash) Len() int { return len(h) }
func (h byKHash) Swap(i, j int) { h[i], h[j] = h[j], h[i] }
func (h byKHash) Less(i, j int) bool { return bytes.Compare(h[i].khash[:],
	h[j].khash[:]) < 0 }

func hashDict(d map[string]interface {}) [hashLength]byte {
	e := make([]hashEntry, len(d))
	n := 0
	for k, v := range d {
		e[n].khash = ObjectHash(k)
		e[n].vhash = ObjectHash(v)
		n++
	}
	sort.Sort(byKHash(e))
	h := new(bytes.Buffer)
	for _, ee := range e {
		h.Write(ee.khash[:])
		h.Write(ee.vhash[:])
	}
	return hash(`d`, h.Bytes())
}

func floatNormalize(f float64) (s string) {
	// sign
	s = `+`
	if f < 0 {
		s = `-`
		f = -f
	}
	// exponent
	e := 0
	for f > 1 {
		f /= 2
		e++
	}
	for f <= .5 {
		f *= 2
		e--
	}
	s += fmt.Sprintf("%d:", e)
	// mantissa
	if f > 1 || f <= .5 {
		panic(f)
	}
	for f != 0 {
		if f >= 1 {
			s += `1`
			f -= 1
		} else {
			s += `0`
		}
		if (f >= 1) {
			panic(f)
		}
		if (len(s) >= 1000) {
			panic(s)
		}
		f *= 2
	}
	return
}

func hashFloat(f float64) [hashLength]byte {
	return hash(`f`, []byte(floatNormalize(f)))
}

func hashInt(i int) [hashLength]byte {
	return hash(`i`, []byte(fmt.Sprintf("%d", i)))
}

func hashBool(b bool) [hashLength]byte {
	bb := []byte(`0`)
	if b {
		bb = []byte(`1`)
	}
	return hash(`b`, bb)
}

func ObjectHash(o interface{}) [hashLength]byte {
	switch v := o.(type) {
	case []interface{}:
		return hashList(v)
	case string:
		return hashUnicode(v)
	case map[string]interface {}:
		return hashDict(v)
	case float64:
		return hashFloat(v)
	case nil:
		return hash(`n`, []byte(``))
	case int:
		return hashInt(v)
	case Set:
		return hashSet(v)
	case bool:
		return hashBool(v)
	default:
		panic(o)
	}
}

func CommonJSONHash(j string) [hashLength]byte {
	var f interface{}
	if err := json.Unmarshal([]byte(j), &f); err != nil {
		panic(err)
	}
	return ObjectHash(f)
}
