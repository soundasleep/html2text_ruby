require "spec_helper"

describe Html2Text do
  describe "#convert" do
    let(:text) { Html2Text.convert(html) }

    context "an empty line" do
      let(:html) { "" }

      it "is an empty line" do
        expect(text).to eq("")
      end
    end

    context "a simple string" do
      let(:html) { "hello world" }

      it "is an empty line" do
        expect(text).to eq("hello world")
      end
    end
  end
end
