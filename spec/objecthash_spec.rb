require "spec_helper"

RSpec.describe ObjectHash do
  it "has a version number" do
    expect(described_class::VERSION).not_to be nil
  end

  context "booleans" do
    it "calculates the hash of true" do
      expect(described_class.hexdigest(true)).to eq "d79cf677c648325ea7725884a9f3c934bfe65786676ddaa9c9caa44a7ee21c39"
    end

    it "calculates the hash of false" do
      expect(described_class.hexdigest(false)).to eq "0cc2b069e520a3eb8e802f5b848d5d91a3b82592ebf613126a1fe6d2144a943b"
    end

    it "calculates the hash of nil" do
      expect(described_class.hexdigest(nil)).to eq "b1611bfd35b81ad23c9fe7bd8bc5aa07054dc641184392f0be8af028638cd39b"
    end
  end

  context "lists" do
    it "calculates the hash of an empty Array" do
      expect(described_class.hexdigest([])).to eq "caca680c6e90ac09f636b2e0d2cacc2b7bd7220b26f102bece1e4a38b5396f0f"
    end
  end

  context "dicts" do
    it "calculates the hash of an empty Hash" do
      expect(described_class.hexdigest({})).to eq "81cae337340f6198c015e0399f536211969d3e5f5634469238f0fa90434f8f4e"
    end
  end

  context "sets" do
    it "calculates the hash of an empty Set" do
      expect(described_class.hexdigest(Set.new)).to eq "40a31778475c27dba852daeb1bfbdcc52065ea11ecfcf9c9f329d5e025ebfa98"
    end
  end

  context "unicode strings" do
    it "calculates the hash of an empty String" do
      expect(described_class.hexdigest("")).to eq "b0ef39e5073c127caca3cf57ecd0c02a9fb845220e80bb130cc0d6f7f1c1a06d"
    end
  end

  context "symbols" do
    it "calculates the hash of an empty Smybol" do
      expect(described_class.hexdigest(:"")).to eq "b0ef39e5073c127caca3cf57ecd0c02a9fb845220e80bb130cc0d6f7f1c1a06d"
    end
  end

  context "integers" do
    it "calculates the hash of 0" do
      expect(described_class.hexdigest(0)).to eq "4a1e767aa650da8d8a56c461b9700b44a7190653ea6f20fd01e3a80eeff23f09"
    end
  end

  context "floats" do
    it "calculates the hash of 0.0" do
      expect(described_class.hexdigest(0.0)).to eq "0601d1c8c99b881441863e989075f153d7aa76fb5f7a0b3a9fea92c54dba3ad3"
    end
  end
end
