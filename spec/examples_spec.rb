# frozen_string_literal: true

require 'spec_helper'

describe Html2Text do
  describe '#convert' do
    let(:text) { described_class.convert(html) }

    examples = Dir["#{File.dirname(__FILE__)}/examples/*.html"]

    examples.each do |filename|
      context filename.to_s do
        let(:html) { File.read(filename) }
        let(:text_file) { filename.sub('.html', '.txt') }
        let(:expected) { described_class.fix_newlines(File.read(text_file)) }

        it 'has an expected output' do
          expect(File.exist?(text_file)).to eq(true), "'#{text_file}' did not exist"
        end

        it 'converts to text' do
          # Write the output if it failed, for easier comparison
          File.write(filename.sub('.html', '.output'), text) unless text.eql?(expected)

          # Quick check, don't try to generate a 500kb+ diff,
          # which can halt the rspec for minutes+
          expect(text.length).to eq expected.length if text.length > 10_000

          # More complete check
          expect(text).to eq expected
        end
      end
    end

    it 'has examples to test' do
      expect(examples.size).not_to eq(0)
    end
  end
end
