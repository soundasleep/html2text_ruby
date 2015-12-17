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

  describe "#remove_leading_and_trailing_whitespace" do
    let(:subject) { Html2Text.new(nil).remove_leading_and_trailing_whitespace(input) }

    context "an empty string" do
      let(:input) { "" }
      it { is_expected.to eq("") }
    end

    context "many new lines" do
      let(:input) { "hello\n  world \n yes" }
      it { is_expected.to eq("hello\nworld\nyes") }
    end
  end
end
