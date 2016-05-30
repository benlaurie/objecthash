lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "objecthash/version"

Gem::Specification.new do |spec|
  spec.name          = "objecthash"
  spec.version       = ObjectHash::VERSION
  spec.authors       = ["Tony Arcieri"]
  spec.email         = ["bascule@gmail.com"]
  spec.licenses      = ["Apache-2.0"]
  spec.homepage      = "https://github.com/cryptosphere/objecthash-ruby"
  spec.summary       = "A content hash algorithm which works across multiple encodings (JSON, Protobufs, etc)"
  spec.description   = <<-DESCRIPTION.strip.gsub(/\s+/, " ")
    A way to cryptographically hash objects (in the JSON-ish sense) that
    works cross-language, and, therefore, cross-encoding.
  DESCRIPTION

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
end
