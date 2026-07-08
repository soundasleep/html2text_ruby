# frozen_string_literal: true

require 'nokogiri'

class Html2Text
  attr_reader :doc

  def initialize(doc)
    @doc = doc
  end

  def self.convert(html)
    html = html.to_s

    if office_document?(html)
      # Emulate the CSS rendering of Office documents
      html = html.gsub('<p class=MsoNormal>', '<br>')
                 .gsub('<o:p>&nbsp;</o:p>', '<br>')
                 .gsub('<o:p></o:p>', '')
    end

    unless html.include?('<html')
      # Stop Nokogiri from inserting in <p> tags
      html = "<div>#{html}</div>"
    end

    html = fix_newlines(replace_entities(html))
    doc = Nokogiri::HTML(html)

    new(doc).convert
  end

  def self.fix_newlines(text)
    # rubocop:disable Performance/StringReplacement
    text.gsub("\r\n", "\n").gsub("\r", "\n")
    # rubocop:enable Performance/StringReplacement
  end

  def self.replace_entities(text)
    # rubocop:disable Performance/StringReplacement
    text.gsub('&nbsp;', ' ').gsub("\u00a0", ' ').gsub('&zwnj;', '')
    # rubocop:enable Performance/StringReplacement
  end

  def convert
    output = iterate_over(doc)
    output = remove_leading_and_trailing_whitespace(output)
    output = remove_unnecessary_empty_lines(output)
    output.strip
  end

  DO_NOT_TOUCH_WHITESPACE = '<do-not-touch-whitespace>'
  IGNORED_TAGS = Set.new(%w[style head title meta script]).freeze

  def remove_leading_and_trailing_whitespace(text)
    # ignore any <pre> blocks, which we don't want to interact with
    pre_blocks = text.split(DO_NOT_TOUCH_WHITESPACE)

    output = []
    pre_blocks.each.with_index do |block, index|
      output << if index.even?
                  block.gsub(/[ \t]*\n[ \t]*/im, "\n").gsub(/ *\t */im, "\t")
                else
                  block
                end
    end

    output.join
  end

  private_class_method def self.office_document?(text)
    text.include?('urn:schemas-microsoft-com:office')
  end

  private

  def remove_unnecessary_empty_lines(text)
    text.gsub(/\n{3,}/, "\n\n")
  end

  def trimmed_whitespace(text)
    # Replace whitespace characters with a space (equivalent to \s)
    # and force any text encoding into UTF-8
    if text.valid_encoding?
      text.gsub(/[\t\n\f\r ]+/, ' ')
    else
      text.force_encoding('WINDOWS-1252')
      trimmed_whitespace(text.encode('UTF-16be', invalid: :replace, replace: '?').encode('UTF-8'))
    end
  end

  def iterate_over(node)
    return trimmed_whitespace(node.text) if node.text?

    name = node.name&.downcase

    return '' if name.nil? || IGNORED_TAGS.include?(name)

    return "\n" if name == 'br' && next_node_is_text?(node)

    return "\n#{DO_NOT_TOUCH_WHITESPACE}#{node.text}#{DO_NOT_TOUCH_WHITESPACE}" if name == 'pre'

    return image_text(node) if name == 'img'

    output = +''
    output << (prefix_whitespace(node) || '')
    node.children.each do |child|
      output << iterate_over(child)
    end
    output << (suffix_whitespace(node) || '')

    output = wrap_link(node, output) if name == 'a'

    output
  end

  def prefix_whitespace(node)
    case node.name.downcase
    when 'hr'
      "\n---------------------------------------------------------------\n"

    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ol', 'ul', 'p'
      "\n\n"

    when 'tr'
      "\n"

    when 'div'
      if node.parent.name == 'div' && (node.parent.text.strip == node.text.strip)
        ''
      else
        "\n"
      end

    when 'td', 'th'
      "\t"

    when 'li'
      '- '
    end
  end

  def suffix_whitespace(node)
    case node.name.downcase
    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p'
      "\n\n"

    when 'br'
      next_name = next_node_name(node)
      "\n" if !next_name.nil? && next_name != 'div'

    when 'li'
      "\n"

    when 'div'
      if next_node_is_text?(node)
        "\n"
      else
        next_name = next_node_name(node)
        "\n" if !next_name.nil? && next_name != 'div'
      end
    end
  end

  # links are returned in [text](link) format
  def wrap_link(node, output)
    href = node.attribute('href')
    name = node.attribute('name')

    output = output.strip

    # remove double [[ ]]s from linking images
    if output[0] == '[' && output[-1] == ']'
      output = output[1, output.length - 2]

      # for linking images, the title of the <a> overrides the title of the <img>
      output = node.attribute('title').to_s if node.attribute('title')
    end

    # if there is no link text, but a title attr
    output = node.attribute('title').to_s if output.empty? && node.attribute('title')

    if href.nil?
      output = "[#{output}]" unless name.nil?
    else
      href = href.to_s

      if href != output && href != "mailto:#{output}" &&
         href != "http://#{output}" && href != "https://#{output}"
        output = if output.empty?
                   href
                 else
                   "[#{output}](#{href})"
                 end
      end
    end

    case next_node_name(node)
    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6'
      output += "\n"
    end

    output
  end

  def image_text(node)
    if node.attribute('title')
      "[#{node.attribute('title')}]"
    elsif node.attribute('alt')
      "[#{node.attribute('alt')}]"
    else
      ''
    end
  end

  def next_node_name(node)
    next_node = node.next_sibling
    until next_node.nil?
      break if next_node.element?

      next_node = next_node.next_sibling
    end

    return unless next_node&.element?

    next_node.name.downcase
  end

  def next_node_is_text?(node)
    !node.next_sibling.nil? && node.next_sibling.text? && !node.next_sibling.text.strip.empty?
  end

  def previous_node_name(node)
    previous_node = node.previous_sibling
    until previous_node.nil?
      break if previous_node.element?

      previous_node = previous_node.previous_sibling
    end

    return unless previous_node&.element?

    previous_node.name.downcase
  end

  def previous_node_is_text?(node)
    !node.previous_sibling.nil? && node.previous_sibling.text? && !node.previous_sibling.text.strip.empty?
  end

  # def previous_node_is_not_text?(node)
  #   return node.previous_sibling.nil? || !node.previous_sibling.text? || node.previous_sibling.text.strip.empty?
  # end
end
