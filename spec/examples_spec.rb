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
          # Write the output if it failed, for easier comparison
          if !text.eql?(expected)
            File.open(filename.sub(".html", ".output"), 'w') do |fp|
              fp.write(text)
            end
          end

          # Quick check, don't try to generate a 500kb+ diff,
          # which can halt the rspec for minutes+
          expect(text.length).to eq expected.length if text.length > 10000

          # More complete check
          expect(text).to eq expected
        end
      end
    end

    it "has examples to test" do
      expect(examples.size).to_not eq(0)
    end
  end
end
