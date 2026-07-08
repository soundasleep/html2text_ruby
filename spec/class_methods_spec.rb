# frozen_string_literal: true

require 'spec_helper'

describe Html2Text do
  describe '.fix_newlines' do
    it 'converts \r\n to \n' do
      expect(Html2Text.fix_newlines("hello\r\nworld")).to eq("hello\nworld")
    end

    it 'converts bare \r to \n' do
      expect(Html2Text.fix_newlines("hello\rworld")).to eq("hello\nworld")
    end
  end

  describe '.replace_entities' do
    it 'replaces &nbsp; entities with spaces' do
      expect(Html2Text.replace_entities('hello&nbsp;world')).to eq('hello world')
    end

    it 'replaces non-breaking space characters with spaces' do
      expect(Html2Text.replace_entities("hello\u00a0world")).to eq('hello world')
    end

    it 'removes zero-width non-joiners' do
      expect(Html2Text.replace_entities('hello&zwnj;world')).to eq('helloworld')
    end
  end
end
