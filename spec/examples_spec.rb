require "spec_helper"

describe Html2Text do
  describe "#convert" do
    let(:text) { Html2Text.convert(html) }

    examples = Dir[File.dirname(__FILE__) + "/examples/*.html"]

    examples.each do |filename|
      context "#{filename}" do
        let(:html) { File.read(filename) }
        let(:text_file) { filename.sub(".html", ".txt") }
        let(:expected) { Html2Text.fix_newlines(File.read(text_file)) }

        it "has an expected output" do
          expect(File.exist?(text_file)).to eq(true), "'#{text_file}' did not exist"
        end

        it "converts to text" do
          expect(text).to eq(expected)
        end
      end
    end

    it "has examples to test" do
      expect(examples.size).to_not eq(0)
    end
  end
end
