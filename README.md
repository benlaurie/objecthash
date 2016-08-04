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

Please note that Strings have [Unicode normalization](http://ruby-doc.org/stdlib-2.2.0/libdoc/unicode_normalize/rdoc/String.html) applied to them by default.
You can disable this if desired by passing in the `normalize: false` keyword
argument to `#digest` or `#hexdigest`. `String#unicode_normalize` was added in
MRI Ruby v2.2.0 and that is the minimum supported version for ObjectHash.

```ruby
>> ObjectHash.hexdigest("Hello, Ruby!")
=> "c92765c1350e6df6800dbadedb3420f398d5f3c7e38a3da48aadb3332280f85f"
>> ObjectHash.hexdigest("Hello, Ruby!", normalize: false)
=> "c92765c1350e6df6800dbadedb3420f398d5f3c7e38a3da48aadb3332280f85f"
>> ObjectHash.hexdigest([{complex: "structures"}, {can: "be"}, {hashed: ["with", "ObjectHash"]}])
=> "18717799dc21fff84b30a0654807348c632bc7498c5e40c025a6c18b9a2666d2"
```

Additionally you can provide a different hash algorithm by instantiating a class:

```ruby
>> objecthash = ObjectHash.new(Digest::SHA512)
=> #<ObjectHash:0x007ffdf39765f0 @hash_algorithm=Digest::SHA512>
>> objecthash.hexdigest("")
=> "58007911bf9f66711ef65e807b26c396a2d6fb464f4381520c5d4a575dbb81510f79d35e349604128a771acf2a117a2afdedc012d83b0eb822668aee0def4747"
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
