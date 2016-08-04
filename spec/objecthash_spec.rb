require "spec_helper"

# rubocop:disable Metrics/LineLength
# rubocop:disable Style/WordArray
# rubocop:disable Style/NumericLiterals

RSpec.describe ObjectHash do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  context "benlaurie/objecthash specs" do
    context "normalization of unicode strings" do
      it "calculates matching digests" do
        u1n = "\u03d3"
        u1d = "\u03d2\u0301"
        expect(u1n).to_not eq u1d
        n1n = described_class.digest(u1n)
        n1d = described_class.digest(u1d)
        expect(n1n).to eq n1d
      end

      it "calculates matching hexdigests" do
        u1n = "\u03d3"
        u1d = "\u03d2\u0301"
        expect(u1n).to_not eq u1d
        n1n = described_class.hexdigest(u1n)
        n1d = described_class.hexdigest(u1d)
        expect(n1n).to eq n1d
      end

      it "calculates matching hexdigests for strings in an Array" do
        u1n = "\u03d3"
        u1d = "\u03d2\u0301"
        l1n1 = [u1n]
        l1n2 = [u1n, u1n]
        l1d = [u1n, u1d]
        expect(l1n1).to_not eq l1n2
        expect(l1n1).to_not eq l1d
        expect(l1n2).to_not eq l1d

        nl1n1 = described_class.hexdigest(l1n1)
        nl1n2 = described_class.hexdigest(l1n2)
        nl1d = described_class.hexdigest(l1d)

        expect(nl1n1).to_not eq nl1n2
        expect(nl1n1).to_not eq nl1d
        expect(nl1n2).to eq nl1d
      end

      it "calculates the same hexdigest hash for a JSON list" do
        expect(described_class.hexdigest(JSON.parse('["foo", "bar"]'))).to eq "32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2"
      end

      it "calculates the same hexdigest hash with normalization true" do
        expect(described_class.hexdigest("\u03d3")).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
        expect(described_class.hexdigest("\u03d2\u0301")).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
      end

      it "calculates a different hexdigest hash with normalization false" do
        expect(described_class.hexdigest("\u03d2\u0301", normalize: false)).to eq "42d5b13fb064849a988a86eb7650a22881c0a9ecf77057a1b07ab0dad385889c"
      end
    end

    # extracted from : https://github.com/benlaurie/objecthash/blob/master/common_json.test
    context "common json" do
      it "calculates known hashes with Arrays of strings" do
        expect(described_class.hexdigest([])).to eq "acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0"
        expect(described_class.hexdigest(["foo"])).to eq "268bc27d4974d9d576222e4cdbb8f7c6bd6791894098645a19eeca9c102d0964"
        expect(described_class.hexdigest(["foo", "bar"])).to eq "32ae896c413cfdc79eec68be9139c86ded8b279238467c216cf2bec4d5f1e4a2"
      end

      # FIXME : failing with a different hash than those found here:
      # https://github.com/benlaurie/objecthash/blob/master/common_json.test#L12
      xit "calculates known hashes with Arrays of Integers" do
        expect(described_class.hexdigest([123])).to eq "2e72db006266ed9cdaa353aa22b9213e8a3c69c838349437c06896b1b34cee36"
        expect(described_class.hexdigest([1, 2, 3])).to eq "925d474ac71f6e8cb35dd951d123944f7cabc5cda9a043cf38cd638cc0158db0"
        expect(described_class.hexdigest([123456789012345])).to eq "f446de5475e2f24c0a2b0cd87350927f0a2870d1bb9cbaa794e789806e4c0836"
        expect(described_class.hexdigest([123456789012345, 678901234567890])).to eq "d4cca471f1c68f62fbc815b88effa7e52e79d110419a7c64c1ebb107b07f7f56"
      end

      it "calculates known hashes with Objects with (lists of) Strings" do
        expect(described_class.hexdigest(JSON.parse("{}"))).to eq "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4"
        expect(described_class.hexdigest(JSON.parse('{"foo": "bar"}'))).to eq "7ef5237c3027d6c58100afadf37796b3d351025cf28038280147d42fdc53b960"
        expect(described_class.hexdigest(JSON.parse('{"foo": ["bar", "baz"], "qux": ["norf"]}'))).to eq "f1a9389f27558538a064f3cc250f8686a0cebb85f1cab7f4d4dcc416ceda3c92"
      end

      it "calculates known hashes with Array of nil value" do
        expect(described_class.hexdigest([nil])).to eq "5fb858ed3ef4275e64c2d5c44b77534181f7722b7765288e76924ce2f9f7f7db"
      end

      it "calculates known hashes with Booleans" do
        expect(described_class.hexdigest(true)).to eq "7dc96f776c8423e57a2785489a3f9c43fb6e756876d6ad9a9cac4aa4e72ec193"
        expect(described_class.hexdigest(false)).to eq "c02c0b965e023abee808f2b548d8d5193a8b5229be6f3121a6f16e2d41a449b3"
      end

      # FIXME : FAILS ON FLOAT NORMALIZE
      xit "calculates known hashes with Floating point numbers" do
        expect(described_class.hexdigest(1.2345)).to eq "844e08b1195a93563db4e5d4faa59759ba0e0397caf065f3b6bc0825499754e0"
        expect(described_class.hexdigest(-10.1234)).to eq "59b49ae24998519925833e3ff56727e5d4868aba4ecf4c53653638ebff53c366"
      end

      # FIXME : FAILS ON FLOAT NORMALIZE
      xit "calculates known hashes with a mixture of all types" do
        expect(described_class.hexdigest(JSON.parse('["foo", {"bar": ["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]'))).to eq "783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213"
      end

      # FIXME : FAILS ON FLOAT NORMALIZE
      xit "calculates known hashes with a mixture of Integers and Floats which are the same in common JSON" do
        expect(described_class.hexdigest(JSON.parse('["foo", {"bar": ["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]'))).to eq "783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213"
      end

      # FIXME : FAILS ON FLOAT NORMALIZE
      xit "calculates known hashes when changing just a key name" do
        expect(described_class.hexdigest(JSON.parse('["foo", {"b4r": ["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]'))).to eq "7e01f8b45da35386e4f9531ff1678147a215b8d2b1d047e690fd9ade6151e431"
      end

      it "order independence" do
        expect(described_class.hexdigest(JSON.parse('{"k1": "v1", "k2": "v2", "k3": "v3"}'))).to eq "ddd65f1f7568269a30df7cafc26044537dc2f02a1a0d830da61762fc3e687057"
        expect(described_class.hexdigest(JSON.parse('{"k2": "v2", "k1": "v1", "k3": "v3"}'))).to eq "ddd65f1f7568269a30df7cafc26044537dc2f02a1a0d830da61762fc3e687057"
      end

      it "unicode" do
        expect(described_class.hexdigest("ԱԲաբ")).to eq "2a2a4485a4e338d8df683971956b1090d2f5d33955a81ecaad1a75125f7a316c"
        expect(described_class.hexdigest("\u03d3")).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
        # Note that this is the same character as above, but hashes
        # differently unless unicode normalisation is applied
        expect(described_class.hexdigest("\u03d2\u0301", normalize: false)).to eq "42d5b13fb064849a988a86eb7650a22881c0a9ecf77057a1b07ab0dad385889c"
        expect(described_class.hexdigest("\u03d2\u0301", normalize: true)).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
      end
    end
  end

  context "booleans" do
    it "calculates the hash of true" do
      expect(described_class.hexdigest(true)).to eq "7dc96f776c8423e57a2785489a3f9c43fb6e756876d6ad9a9cac4aa4e72ec193"
    end

    it "calculates the hash of false" do
      expect(described_class.hexdigest(false)).to eq "c02c0b965e023abee808f2b548d8d5193a8b5229be6f3121a6f16e2d41a449b3"
    end

    it "calculates the hash of nil" do
      expect(described_class.hexdigest(nil)).to eq "1b16b1df538ba12dc3f97edbb85caa7050d46c148134290feba80f8236c83db9"
    end
  end

  context "lists" do
    it "calculates the hash of an empty Array" do
      expect(described_class.hexdigest([])).to eq "acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0"
    end
  end

  context "dicts" do
    it "calculates the hash of an empty Hash" do
      expect(described_class.hexdigest({})).to eq "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4"
    end
  end

  context "sets" do
    it "calculates the hash of an empty Set" do
      expect(described_class.hexdigest(Set.new)).to eq "043a718774c572bd8a25adbeb1bfcd5c0256ae11cecf9f9c3f925d0e52beaf89"
    end
  end

  context "symbols" do
    it "calculates the hash of an empty Smybol" do
      expect(described_class.hexdigest(:"")).to eq "0bfe935e70c321c7ca3afc75ce0d0ca2f98b5422e008bb31c00c6d7f1f1c0ad6"
    end
  end

  context "integers" do
    it "calculates the hash of 0" do
      expect(described_class.hexdigest(0)).to eq "a4e167a76a05add8a8654c169b07b0447a916035aef602df103e8ae0fe2ff390"
    end
  end

  context "floats" do
    it "calculates the hash of 0.0" do
      expect(described_class.hexdigest(0.0)).to eq "60101d8c9cb988411468e38909571f357daa67bff5a7b0a3f9ae295cd4aba33d"
    end
  end
end
