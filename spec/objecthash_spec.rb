require "spec_helper"

RSpec.describe ObjectHash do
  it "has a version number" do
    expect(ObjectHash::VERSION).not_to be nil
  end
end
