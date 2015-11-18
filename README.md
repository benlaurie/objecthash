# objecthash

A way to cryptographically hash objects (in the JSON-ish sense) that works cross-language. And, therefore, cross-encoding.

Build it with:

```shellsession
$ make get
GOPATH=`pwd` go get golang.org/x/text/unicode/norm
$ make
<lots of test output>

OK (I hope)
```

You only need to do the `make get` the first time.

Take a look at `objecthash_test.*`.

Comments/bugs/patches welcome.

## What's it good for?

### Signing and verification

Now you can sign objects regardless of the transport encoding and programming language used.

### Verifiable append-only logs of objects

[Certificate Transparency](http://www.certificate-transparency.org/) provides a verifiable append-only log of certificates. The same thing can be done for arbitrary objects using `objecthash`. And you can serve the objects themselves in whatever format is handy - JSON, XML, RDF ... you name it. _(note to self: implement XML and RDF encodings)_

### Redaction

Sometimes you want to show different people different things - maybe some information is private, or maybe your policy changed about what is shown since you wrote the log (remember that once you've logged to a verifiable append-only log you can't change the hash of the log entry). `objecthash` allows you to redact parts of objects, yet still verify them. For example, the JSON structure:

```json
["foo", {"bar": ["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]
```

has hash `783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213`. The substructure:

```json
{"bar": ["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}
```

has hash `96e2aab962831956c80b542f056454be411f870055d37805feb3007c855bd823`. The redacted structure:

```json
["foo", "**REDACTED**96e2aab962831956c80b542f056454be411f870055d37805feb3007c855bd823"]
```

matches the original hash, `783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213`. So does:

```json
["foo", {"bar": ["**REDACTED**82f70430fa7b78951b3c4634d228756a165634df977aa1fada051d6828e78f30", null, 1.0, 1.5, "**REDACTED**1195afc7f0b70bb9d7960c3615668e072a1cbfbbb001f84871fd2e222a87be1d", 1000.0, 2.0, -23.1234, 2.0]}]
```

or even:

```json
["foo", {"**REDACTED**e303ce0bd0f4c1fdfe4cc1e837d7391241e2e047df10fa6101733dc120675dfe": ["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]
```
Magic!

### What You Hash Is What You Get

Most object signing/verifying schemes (e.g. X509v3, JOSE) work by signing or verifying some canonical binary or text form of the object, which you then decode and hope you end up with what was actually signed. Using `objecthash` you decode first, *then* verify. If verification works, then the object you have is the object that was signed in the first place.

## Redactability

If your data is guessable, then redaction doesn't really help: the data can easily be reconstructed with a brute force attack. So, `objecthash` offers a way to decorate an object so that everything in it can be redacted _and_ be safe from brute-forcing. `redactable(o)` turns every basic object (except keys) in `o` into an array with two entries, the first being a 32 byte random string. Since keys are required to be strings, those are prefixed with the random string.

`unredactable(o)` reverses the process.

## Common vs. Python JSON

Python distinguishes between int and float when parsing JSON, which makes it incompatible with GO - all numbers are float in Go. Common JSON functions convert Python JSON to Common JSON first.
