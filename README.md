# objecthash

A way to cryptographically hash objects (in the JSON-ish sense) that works cross-language. And, therefore, cross-encoding.

Build it with:

```
% make get
GOPATH=`pwd` go get golang.org/x/text/unicode/norm
% make
<lots of test output>

OK (I hope)
```

You only need to do the `make get` the first time.

Take a look at `objecthash_test.*`.

Comments/bugs/patches welcome.
