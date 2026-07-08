# frozen_string_literal: true

require 'spec_helper'

# Subclassing Html2Text to override the default behaviour is supported
# (see #30); these specs pin the extension points that subclasses rely on.
class CustomListPrefix < Html2Text
  private

  def prefix_whitespace(node)
    return '* ' if node.name.downcase == 'li'

    super
  end
end

class CustomLinkFormat < Html2Text
  private

  def wrap_link(node, output)
    "#{output.strip} <#{node.attribute('href')}>"
  end
end

class SkipsBlockquotes < Html2Text
  private

  def iterate_over(node)
    return '' if !node.text? && node.name.downcase == 'blockquote'

    super
  end
end

class CustomImageText < Html2Text
  private

  def image_text(node)
    "(image: #{node.attribute('src')})"
  end
end

describe 'subclassing Html2Text' do
  it 'can override prefix_whitespace' do
    text = CustomListPrefix.convert('<ul><li>one</li><li>two</li></ul>')
    expect(text).to eq("* one\n* two")
  end

  it 'can override wrap_link' do
    text = CustomLinkFormat.convert('<a href="http://example.com">hello</a>')
    expect(text).to eq('hello <http://example.com>')
  end

  it 'can override iterate_over' do
    text = SkipsBlockquotes.convert('<p>before</p><blockquote>quoted</blockquote><p>after</p>')
    expect(text).to eq("before\n\nafter")
  end

  it 'can override image_text' do
    text = CustomImageText.convert('<img src="pic.png" alt="a picture">')
    expect(text).to eq('(image: pic.png)')
  end

  it 'uses the subclass from self.convert' do
    expect(CustomListPrefix.convert('plain text')).to eq('plain text')
  end
end
