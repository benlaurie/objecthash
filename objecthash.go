package objecthash

import (
	"bytes"
	"crypto/sha256"
	"encoding/json"
	"errors"
	"fmt"
	"sort"
)

var (
	ErrNormalizingFloat       = errors.New("ErrNormalizingFloat")
	ErrUnrecognizedObjectType = errors.New("ErrUnrecognizedObjectType")
)

//import "golang.org/x/text/unicode/norm"

func hash(t byte, b []byte) []byte {
	h := sha256.New()
	h.Write([]byte{t})
	h.Write(b)
	return h.Sum(nil)
}

// FIXME: if What You Hash Is What You Get, then this needs to be safe
// to use as a set.
// Note: not actually safe to use as a set
type Set []interface{}

type sortableHashes [][]byte

func (h sortableHashes) Len() int           { return len(h) }
func (h sortableHashes) Swap(i, j int)      { h[i], h[j] = h[j], h[i] }
func (h sortableHashes) Less(i, j int) bool { return bytes.Compare(h[i], h[j]) < 0 }

func hashSet(s Set) ([]byte, error) {
	h := make([][]byte, len(s))
	for n, e := range s {
		var err error
		if h[n], err = ObjectHash(e); err != nil {
			return nil, err
		}
	}
	sort.Sort(sortableHashes(h))
	b := new(bytes.Buffer)
	var prev []byte
	for _, hh := range h {
		if !bytes.Equal(hh, prev) {
			b.Write(hh)
		}
		prev = hh
	}
	return hash('s', b.Bytes()), nil
}

func hashList(l []interface{}) ([]byte, error) {
	h := new(bytes.Buffer)
	for _, o := range l {
		var b []byte
		var err error
		if b, err = ObjectHash(o); err != nil {
			return nil, err
		}
		h.Write(b)
	}
	return hash('l', h.Bytes()), nil
}

func hashUnicode(s string) ([]byte, error) {
	//return hash(`u`, norm.NFC.Bytes([]byte(s)))
	return hash('u', []byte(s)), nil
}

type hashEntry struct {
	khash []byte
	vhash []byte
}
type byKHash []hashEntry

func (h byKHash) Len() int      { return len(h) }
func (h byKHash) Swap(i, j int) { h[i], h[j] = h[j], h[i] }
func (h byKHash) Less(i, j int) bool {
	return bytes.Compare(h[i].khash, h[j].khash) < 0
}

func hashDict(d map[string]interface{}) ([]byte, error) {
	e := make([]hashEntry, len(d))
	n := 0
	for k, v := range d {
		var err error
		if e[n].khash, err = ObjectHash(k); err != nil {
			return nil, err
		}
		if e[n].vhash, err = ObjectHash(v); err != nil {
			return nil, err
		}
		n++
	}
	sort.Sort(byKHash(e))
	h := new(bytes.Buffer)
	for _, ee := range e {
		h.Write(ee.khash)
		h.Write(ee.vhash)
	}
	return hash('d', h.Bytes()), nil
}

func floatNormalize(f float64) (string, error) {
	// sign
	s := `+`
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
		return "", ErrNormalizingFloat
	}
	for f != 0 {
		if f >= 1 {
			s += `1`
			f -= 1
		} else {
			s += `0`
		}
		if f >= 1 {
			return "", ErrNormalizingFloat
		}
		if len(s) >= 1000 {
			return "", ErrNormalizingFloat
		}
		f *= 2
	}
	return s, nil
}

func hashFloat(f float64) ([]byte, error) {
	var n string
	var err error
	if n, err = floatNormalize(f); err != nil {
		return nil, err
	}
	return hash('f', []byte(n)), nil
}

func hashInt(i int) ([]byte, error) {
	return hash('i', []byte(fmt.Sprintf("%d", i))), nil
}

func hashBool(b bool) ([]byte, error) {
	var bb []byte
	if b {
		bb = []byte{'1'}
	} else {
		bb = []byte{'0'}
	}
	return hash('b', bb), nil
}

func ObjectHash(o interface{}) ([]byte, error) {
	switch v := o.(type) {
	case []interface{}:
		return hashList(v)
	case string:
		return hashUnicode(v)
	case map[string]interface{}:
		return hashDict(v)
	case float64:
		return hashFloat(v)
	case nil:
		return hash('n', nil), nil
	case int:
		return hashInt(v)
	case Set:
		return hashSet(v)
	case bool:
		return hashBool(v)
	default:
		return nil, ErrUnrecognizedObjectType
	}
}

func CommonJSONHash(j []byte) ([]byte, error) {
	var f interface{}
	if err := json.Unmarshal(j, &f); err != nil {
		return nil, err
	}
	return ObjectHash(f)
}
