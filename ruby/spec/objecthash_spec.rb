require "spec_helper"

# Note many tests extracted from:
# https://github.com/benlaurie/objecthash/blob/master/common_json.test
#
# ALL hashes were first calculated in the Python implementation
# at benlaurie/objecthash to ensure interop

# rubocop:disable Metrics/LineLength
# rubocop:disable Style/WordArray

RSpec.describe ObjectHash do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  context "calculates hashes from JSON" do
    it "with Arrays of Integers" do
      expect(described_class.hexdigest(JSON.parse("[123]"))).to eq "1b93f704451e1a7a1b8c03626ffcd6dec0bc7ace947ff60d52e1b69b4658ccaa"
      expect(described_class.hexdigest(JSON.parse("[1, 2, 3]"))).to eq "157bf16c70bd4c9673ffb5030552df0ee2c40282042ccdf6167850edc9044ab7"
      expect(described_class.hexdigest(JSON.parse("[123456789012345]"))).to eq "3488b9bc37cce8223a032760a9d4ef488cdfebddd9e1af0b31fcd1d7006369a4"
      expect(described_class.hexdigest(JSON.parse("[123456789012345, 678901234567890]"))).to eq "031ef1aaeccea3bced3a1c6237a4fc00ed4d629c9511922c5a3f4e5c128b0ae4"
    end

    it "with Objects with (lists of) Strings" do
      expect(described_class.hexdigest(JSON.parse("{}"))).to eq "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4"
      expect(described_class.hexdigest(JSON.parse('{"foo": "bar"}'))).to eq "7ef5237c3027d6c58100afadf37796b3d351025cf28038280147d42fdc53b960"
      expect(described_class.hexdigest(JSON.parse('{"foo": ["bar", "baz"], "qux": ["norf"]}'))).to eq "f1a9389f27558538a064f3cc250f8686a0cebb85f1cab7f4d4dcc416ceda3c92"
    end

    it "with a mixture of all types" do
      expect(described_class.hexdigest(JSON.parse('["foo", {"bar": ["baz", null, 1.0, 1.5, 0.0001, 1000.0, 2.0, -23.1234, 2.0]}]'))).to eq "783a423b094307bcb28d005bc2f026ff44204442ef3513585e7e73b66e3c2213"
    end

    it "with a mixture of Strings, Integers, Floats, and null" do
      expect(described_class.hexdigest(JSON.parse('["foo", {"bar": ["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]'))).to eq "726e7ae9e3fadf8a2228bf33e505a63df8db1638fa4f21429673d387dbd1c52a"
    end

    it "with a mixture of Strings, Integers, Floats, null, with a changed key name" do
      expect(described_class.hexdigest(JSON.parse('["foo", {"b4r": ["baz", null, 1, 1.5, 0.0001, 1000, 2, -23.1234, 2]}]'))).to eq "ea590d3d54c53c6d285bffe38f860ce8776d100a145240cc820d08e1a26b15c8"
    end

    it "with a mixture of Strings, Integers, and null" do
      expect(described_class.hexdigest(JSON.parse('["foo", {"bar": ["baz", null, 1, 1000, 2, 2]}]'))).to eq "d72e5c150b7dab0127688b9c9d8180242156819f9d92736ee63c22376fd107f6"
    end
  end

  context "calculates hashes from Ruby" do
    context "Strings" do
      it "normalizes by default when calculating a digest" do
        u1n = "\u03d3"
        u1d = "\u03d2\u0301"
        expect(u1n).to_not eq u1d
        n1n = described_class.digest(u1n)
        n1d = described_class.digest(u1d)
        expect(n1n).to eq n1d
      end

      it "normalizes by default when calculating a hexdigest" do
        u1n = "\u03d3"
        u1d = "\u03d2\u0301"
        expect(u1n).to_not eq u1d
        n1n = described_class.hexdigest(u1n)
        n1d = described_class.hexdigest(u1d)
        expect(n1n).to eq n1d
      end

      it "calculates same hexdigest for related strings with normalization default true" do
        expect(described_class.hexdigest("\u03d3")).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
        expect(described_class.hexdigest("\u03d2\u0301")).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
      end

      it "calculates a different hexdigest with normalization false" do
        expect(described_class.hexdigest("\u03d3")).to eq "f72826713a01881404f34975447bd6edcb8de40b191dc57097ebf4f5417a554d"
        expect(described_class.hexdigest("\u03d2\u0301", normalize: false)).to eq "42d5b13fb064849a988a86eb7650a22881c0a9ecf77057a1b07ab0dad385889c"
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

    context "Booleans" do
      it "calculates true" do
        expect(described_class.hexdigest(true)).to eq "7dc96f776c8423e57a2785489a3f9c43fb6e756876d6ad9a9cac4aa4e72ec193"
      end

      it "calculates false" do
        expect(described_class.hexdigest(false)).to eq "c02c0b965e023abee808f2b548d8d5193a8b5229be6f3121a6f16e2d41a449b3"
      end

      it "calculates nil" do
        expect(described_class.hexdigest(nil)).to eq "1b16b1df538ba12dc3f97edbb85caa7050d46c148134290feba80f8236c83db9"
      end
    end

    context "Arrays" do
      it "calculates an empty Array" do
        expect(described_class.hexdigest([])).to eq "acac86c0e609ca906f632b0e2dacccb2b77d22b0621f20ebece1a4835b93f6f0"
      end

      it "calculates an Array of Strings" do
        expect(described_class.hexdigest(["a", "b", "c"])).to eq "f88c49b5f5a00d187aed48f4a20d300fde5b1aa8434e21ffdf2b6f615d1b65a5"
      end

      it "calculates and normalizes Strings in an Array" do
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

      it "calculates an Array of Integers" do
        expect(described_class.hexdigest([1, 2, 3])).to eq "157bf16c70bd4c9673ffb5030552df0ee2c40282042ccdf6167850edc9044ab7"
      end

      it "calculates an Array of Floats" do
        expect(described_class.hexdigest([1.01, 2.01, 3.01])).to eq "9d8a79a15670f3b38dd37db59d93927337e61a46f3d412ad1cc6e38826eaf74c"
      end

      it "calculates an Array of nil" do
        expect(described_class.hexdigest([nil])).to eq "5fb858ed3ef4275e64c2d5c44b77534181f7722b7765288e76924ce2f9f7f7db"
      end

      it "calculates an Array of Booleans" do
        expect(described_class.hexdigest([true, false])).to eq "6fc9b81eb5560f918a85da608f22ca06fb697a162953e88665a8896b442fc6a8"
      end

      it "calculates an Array of Hashes" do
        expect(described_class.hexdigest([{ foo: "bar" }, { baz: "qux" }])).to eq "71f1aa1c50e62dbd1a17116f7c56c92aca0d22135ad1c071c0d8929d965ba81f"
      end
    end

    context "Hashes" do
      it "calculates an empty Hash" do
        expect(described_class.hexdigest({})).to eq "18ac3e7343f016890c510e93f935261169d9e3f565436429830faf0934f4f8e4"
      end

      it "calculates a Hash with an Integer value" do
        expect(described_class.hexdigest(foo: 1)).to eq "bf4c58f5e308e31e2cd64bdbf7a01b9b595a13602438be5e912c7d94f6d8177a"
      end

      it "calculates a Hash with an Float value" do
        expect(described_class.hexdigest(foo: 1.01)).to eq "e49f310ffc2fb04b1d5e8943cbeb17e62057f2edba2dab604e92d8c6acb2bb65"
      end

      it "calculates a Hash with Boolean values" do
        expect(described_class.hexdigest(foo: true, bar: false)).to eq "f1452c86e0bd6ba0244a8c5627d148deb361696902bd3e90b9e6fc404eefd4bd"
      end

      it "calculates hash with order independence" do
        expect(described_class.hexdigest("k1": "v1", "k2": "v2", "k3": "v3")).to eq "ddd65f1f7568269a30df7cafc26044537dc2f02a1a0d830da61762fc3e687057"
        expect(described_class.hexdigest("k2": "v2", "k1": "v1", "k3": "v3")).to eq "ddd65f1f7568269a30df7cafc26044537dc2f02a1a0d830da61762fc3e687057"
      end

      it "calculates hash with indifferent access" do
        expect(described_class.hexdigest(k1: "v1")).to eq "5607502f0ccf1e905a2525f3325ab0362efd94e3f6dfcf8de436d91d31bc0482"
        expect(described_class.hexdigest("k1": "v1")).to eq "5607502f0ccf1e905a2525f3325ab0362efd94e3f6dfcf8de436d91d31bc0482"
      end
    end

    context "Sets" do
      it "calculates the hash of an empty Set" do
        expect(described_class.hexdigest(Set.new)).to eq "043a718774c572bd8a25adbeb1bfcd5c0256ae11cecf9f9c3f925d0e52beaf89"
      end
    end

    context "Symbols" do
      it "calculates the hash of an empty Smybol" do
        expect(described_class.hexdigest(:"")).to eq "0bfe935e70c321c7ca3afc75ce0d0ca2f98b5422e008bb31c00c6d7f1f1c0ad6"
      end

      it "calculates the hash of an non-empty Smybol" do
        expect(described_class.hexdigest(:f123)).to eq "9866a3b98a5d8541cc27b269edd9933cadc2a4648d49eeb2754d100c97718d59"
      end

      it "calculates the hash of an String the same as Symbol" do
        expect(described_class.hexdigest("f123")).to eq "9866a3b98a5d8541cc27b269edd9933cadc2a4648d49eeb2754d100c97718d59"
      end
    end

    context "Integers" do
      it "calculates the hash of common integers" do
        expect(described_class.hexdigest(-1)).to eq "f105b11df43d5d321f5c773ef904af979024887b4d2b0fab699387f59e2ff01e"
        expect(described_class.hexdigest(0)).to eq "a4e167a76a05add8a8654c169b07b0447a916035aef602df103e8ae0fe2ff390"
        expect(described_class.hexdigest(10)).to eq "73f6128db300f3751f2e509545be996d162d20f9e030864632f85e34fd0324ce"
        expect(described_class.hexdigest(1000)).to eq "a3346d18105ef801c3598fec426dcc5d4be9d0374da5343f6c8dcbdf24cb8e0b"
      end
    end

    context "Floats" do
      it "calculates the hash of common floats" do
        expect(described_class.hexdigest(-1.0)).to eq "f706daa44d7e40e21ea202c36119057924bb28a49949d8ddaa9c8c3c9367e602"
        expect(described_class.hexdigest(0.0)).to eq "60101d8c9cb988411468e38909571f357daa67bff5a7b0a3f9ae295cd4aba33d"
        expect(described_class.hexdigest(0.001)).to eq "47fe626453d51b9419d7e15d9b006b2263a9287c28a35d080cd949609a6c472d"
        expect(described_class.hexdigest(10.0)).to eq "084cfc7219e4163b67f2f9d00f03b50f1c7bdfce48c2b90276ff6784f6529b21"
        expect(described_class.hexdigest(1000.0)).to eq "09b29bf3f8bea85fbf7dd5b3e185e9c3a007761f8824a54d4d518578c9360419"
        expect(described_class.hexdigest(1.2345)).to eq "844e08b1195a93563db4e5d4faa59759ba0e0397caf065f3b6bc0825499754e0"
        expect(described_class.hexdigest(-10.1234)).to eq "59b49ae24998519925833e3ff56727e5d4868aba4ecf4c53653638ebff53c366"
      end
    end
  end
end
