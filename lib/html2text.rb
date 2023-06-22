# frozen_string_literal: true

require 'nokogiri'

class Html2Text
  attr_reader :doc

  NEWLINE = "\n"

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

    Html2Text.new(doc).convert
  end

  def self.fix_newlines(text)
    text.gsub("\r\n", NEWLINE).gsub("\r", NEWLINE)
  end

  def self.replace_entities(text)
    whitespace = ' '
    text.gsub('&nbsp;', whitespace).gsub("\u00a0", whitespace).gsub('&zwnj;', '')
  end

  def convert
    output = iterate_over(doc)
    output = remove_leading_and_trailing_whitespace(output)
    output = remove_unnecessary_empty_lines(output)
    output.strip
  end

  DO_NOT_TOUCH_WHITESPACE = '<do-not-touch-whitespace>'

  def remove_leading_and_trailing_whitespace(text)
    # ignore any <pre> blocks, which we don't want to interact with
    pre_blocks = text.split(DO_NOT_TOUCH_WHITESPACE)

    output = []
    pre_blocks.each.with_index do |block, index|
      output << if index.even?
                  block.gsub(/[ \t]*\n[ \t]*/im, NEWLINE).gsub(/ *\t */im, "\t")
                else
                  block
                end
    end

    output.join
  end

  def self.office_document?(text)
    text.include?('urn:schemas-microsoft-com:office')
  end

  private

  def remove_unnecessary_empty_lines(text)
    text.gsub(/\n\n\n*/im, "\n\n")
  end

  def trimmed_whitespace(text)
    # Replace whitespace characters with a space (equivalent to \s)
    # and force any text encoding into UTF-8
    if text.valid_encoding?
      text.gsub(/[\t\n\f\r ]+/im, ' ')
    else
      text.force_encoding('WINDOWS-1252')
      trimmed_whitespace(text.encode('UTF-16be', invalid: :replace, replace: '?').encode('UTF-8'))
    end
  end

  def iterate_over(node)
    return NEWLINE if node.name.casecmp('br').zero? && next_node_is_text?(node)

    return trimmed_whitespace(node.text) if node.text?

    return '' if %w[style head title meta script].include?(node.name.downcase)

    return "\n#{DO_NOT_TOUCH_WHITESPACE}#{node.text}#{DO_NOT_TOUCH_WHITESPACE}" if node.name.casecmp('pre').zero?

    output = iterate_over_output(node)

    iterate_over_link_image(output, node)
  end

  def prefix_whitespace(node)
    case node.name.downcase
    when 'hr'
      "\n---------------------------------------------------------------\n"

    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'ol', 'ul', 'p'
      NEWLINE * 2

    when 'tr'
      NEWLINE

    when 'div'
      prefix_whitespace_div_clause(node)

    when 'td', 'th'
      "\t"

    when 'li'
      '- '
    end
  end

  def suffix_whitespace(node)
    case node.name.downcase
    when 'h1', 'h2', 'h3', 'h4', 'h5', 'h6', 'p'
      # add another line
      NEWLINE.to_s * 2

    when 'br'
      suffix_whitespace_br_clause(node)

    when 'li'
      NEWLINE

    when 'div'
      suffix_whitespace_div_clause(node)
    end
  end

  # links are returned in [text](link) format
  def wrap_link(node, output)
    href = node.attribute('href')
    name = node.attribute('name')

    output = output.strip

    # remove double [[ ]]s from linking images
    output = remove_double_brackets(output, node)

    # if there is no link text, but a title attr
    output = node.attribute('title').to_s if output.empty? && node.attribute('title')

    output = check_href(output, href, name)

    output += NEWLINE if %w[h1 h2 h3 h4 h5 h6].include? next_node_name(node)

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

    next_node.name.downcase if next_node&.element?
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

    previous_node.name.downcase if previous_node&.element?
  end

  def previous_node_is_text?(node)
    !node.previous_sibling.nil? && node.previous_sibling.text? && !node.previous_sibling.text.strip.empty?
  end

  def remove_double_brackets(output, node)
    return output unless output[0] == '[' && output[-1] == ']'

    output = output[1, output.length - 2]

    # for linking images, the title of the <a> overrides the title of the <img>
    return node.attribute('title').to_s if node.attribute('title')

    output
  end

  def check_href(output, href, name)
    return "[#{output}]" if href.nil? and !name.nil?
    return output if href.nil?

    href = href.to_s

    return output.empty? ? href : "[#{output}](#{href})" if valid_href?(href, output)

    output
  end

  def valid_href?(href, output)
    href != output && href != "mailto:#{output}" && href != "http://#{output}" && href != "https://#{output}"
  end

  def next_node_is_div?(node)
    next_node_name(node) == 'div'
  end

  def suffix_whitespace_br_clause(node)
    return NEWLINE if next_node_name(node) != 'div' && !next_node_name(node).nil?

    nil
  end

  def suffix_whitespace_div_clause(node)
    return NEWLINE if next_node_is_text?(node)
    return NEWLINE if next_node_name(node) != 'div' && !next_node_name(node).nil?

    nil
  end

  def prefix_whitespace_div_clause(node)
    node.parent.name == 'div' && (node.parent.text.strip == node.text.strip) ? '' : NEWLINE
  end

  def iterate_over_link_image(output, node)
    return output if node.name.nil?

    case node.name.downcase
    when 'a'
      wrap_link(node, output)
    when 'img'
      image_text(node)
    else
      output
    end
  end

  def iterate_over_node_map(node)
    node.children.map do |child|
      iterate_over(child) unless child.name.nil?
    end
  end

  def iterate_over_output(node)
    output = []
    output << prefix_whitespace(node)
    output += iterate_over_node_map(node)
    output << suffix_whitespace(node)
    output.compact.join || ''
  end
end
