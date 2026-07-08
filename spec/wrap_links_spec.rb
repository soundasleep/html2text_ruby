# frozen_string_literal: true

require 'spec_helper'

describe Html2Text do
  describe 'the wrap_links option' do
    it 'defaults to wrapping links in [text](href) format' do
      text = Html2Text.convert('<a href="https://example.com">Click Here!</a>')
      expect(text).to eq('[Click Here!](https://example.com)')
    end

    it 'renders links as "text: href" with wrap_links: false' do
      text = Html2Text.convert('<a href="https://example.com">Click Here!</a>', wrap_links: false)
      expect(text).to eq('Click Here!: https://example.com')
    end

    it 'is also accepted by the initializer' do
      doc = Nokogiri::HTML('<a href="https://example.com">Click Here!</a>')
      expect(Html2Text.new(doc, wrap_links: false).convert).to eq('Click Here!: https://example.com')
    end

    it 'unwraps linked images' do
      text = Html2Text.convert('<a href="http://x.com"><img src="i.png" alt="two"></a>', wrap_links: false)
      expect(text).to eq('two: http://x.com')
    end

    it 'still renders links with no text as the bare href' do
      text = Html2Text.convert('<a href="http://x.com"></a>', wrap_links: false)
      expect(text).to eq('http://x.com')
    end

    it 'still renders links whose text equals the href as just the text' do
      text = Html2Text.convert('<a href="http://example.com">http://example.com</a>', wrap_links: false)
      expect(text).to eq('http://example.com')
    end

    it 'still renders mailto links matching their text as just the text' do
      text = Html2Text.convert('<a href="mailto:a@b.com">a@b.com</a>', wrap_links: false)
      expect(text).to eq('a@b.com')
    end
  end
end
