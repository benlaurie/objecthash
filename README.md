# ObjectHash

[![Gem Version](https://badge.fury.io/rb/objecthash.svg)](https://rubygems.org/gems/objecthash)
[![Build Status](https://secure.travis-ci.org/cryptosphere/objecthash-ruby.svg?branch=master)](https://travis-ci.org/cryptosphere/objecthash-ruby)
[![Apache 2 licensed](https://img.shields.io/badge/license-Apache2-blue.svg)](https://github.com/cryptosphere/objecthash-ruby/blob/master/LICENSE)

A content hash algorithm which works across multiple encodings (JSON, Protobufs, etc).

This gem is a Ruby implementation of a format [originally created by Ben Laurie](https://github.com/benlaurie/objecthash).

## Installation

Add this line to your application's Gemfile:

```ruby
gem "objecthash"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install objecthash

## Usage

ObjectHash can calculate a digest of object graphs composed of a constrained
set of types. The following types are supported:

* Booleans: `true`, `false`, `nil`
* Numerics: Fixnum, Float
* Array
* Hash
* Set
* String (and Symbol)

The `#digest` and `#hexdigest` methods are available on ObjectHash:

```ruby
>> ObjectHash.hexdigest("Hello, Ruby!")
=> "9c72561c53e0d66f08d0abedbd43023f895d3f7c3ea8d34aa8da3b3322088ff5"
>> ObjectHash.hexdigest([{complex: "structures"}, {can: "be"}, {hashed: ["with", "ObjectHash"]}])
=> "81177799cd12ff8fb4030a56847043c836b27c94c8e5040c526a1cb8a962662d"
```

Additionally you can provide a different hash algorithm by instantiating a class:

```ruby
>> objecthash = ObjectHash.new(Digest::SHA512)
=> #<ObjectHash:0x007ffdf39765f0 @hash_algorithm=Digest::SHA512>
>> objecthash.hexdigest("")
=> "85009711fbf96617e16fe508b7623c692a6dbf64f4341825c0d5a475d5bb1815f0973de543694021a877a1fca211a7a2dfde0c218db3e08b2266a8eed0fe7474"
```

For compatibility reasons it's recommended you use the default hash algorithm (SHA-256).

## TODO

* Adapt better tests from upstream objecthash_test.py
* Redaction support

## Contributing

* Fork this repository on Github
* Make your changes and send a pull request
* If your changes look good, we'll merge them

## Copyright

Copyright (c) 2016 Tony Arcieri, Ben Laurie. Distributed under the Apache 2.0 License.
See LICENSE file for further details.
