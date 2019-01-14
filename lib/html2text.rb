require 'nokogiri'

class Html2Text
  attr_reader :doc

  def initialize(doc, allowed_html_tags = [])
    @doc = doc
    @allowed_html_tags = allowed_html_tags
  end

  def self.convert(html, allowed_html_tags = [])
    html = html.to_s
    html = fix_newlines(replace_entities(html))
    doc = Nokogiri::HTML(html)

    Html2Text.new(doc, allowed_html_tags).convert
  end

  def self.fix_newlines(text)
    text.gsub("\r\n", "\n").gsub("\r", "\n")
  end

  def self.replace_entities(text)
    text.gsub("&nbsp;", " ").gsub("\u00a0", " ")
  end

  def convert
    output = iterate_over(doc)
    output = remove_leading_and_trailing_whitespace(output)
    output = remove_unnecessary_empty_lines(output)
    output.strip
  end

  def remove_leading_and_trailing_whitespace(text)
    text.gsub(/[ \t]*\n[ \t]*/im, "\n").gsub(/ *\t */im, "\t")
  end

  def remove_unnecessary_empty_lines(text)
    text.gsub(/\n\n\n*/im, "\n\n")
  end

  def trimmed_whitespace(text)
    # Replace whitespace characters with a space (equivalent to \s)
    text.gsub(/[\t\n\f\r ]+/im, " ")
  end

  def next_node_name(node)
    next_node = node.next_sibling
    while next_node != nil
      break if next_node.element?
      next_node = next_node.next_sibling
    end

    if next_node && next_node.element?
      next_node.name.downcase
    end
  end

  def iterate_over(node)
    return trimmed_whitespace(node.text) if node.text?

    if ["style", "head", "title", "meta", "script"].include?(node.name.downcase)
      return ""
    end

    output = []

    output << prefix_whitespace(node)
    output += node.children.map do |child|
      iterate_over(child)
    end
    output << suffix_whitespace(node)

    output = output.compact.join("") || ""

    if node.name.downcase == "a"
      output = wrap_link(node, output)
    end
    if node.name.downcase == "img"
      output = image_text(node)
    end
    if @allowed_html_tags.include?(node.name.downcase)
      output = pass_through_html(node)
    end

    output
  end

  def prefix_whitespace(node)
    case node.name.downcase
      when "hr"
        "---------------------------------------------------------------\n"

      when "h1", "h2", "h3", "h4", "h5", "h6", "ol", "ul"
        "\n"

      when "tr", "p", "div"
        "\n"

      when "td", "th"
        "\t"

      when "li"
        "- "
    end
  end

  def suffix_whitespace(node)
    case node.name.downcase
      when "h1", "h2", "h3", "h4", "h5", "h6"
        # add another line
        "\n"

      when "p", "br"
        "\n" if next_node_name(node) != "div"

      when "li"
        "\n"

      when "div"
        # add one line only if the next child isn't a div
        "\n" if next_node_name(node) != "div" && next_node_name(node) != nil
    end
  end

  # links are returned in [text](link) format
  def wrap_link(node, output)
    href = node.attribute("href")
    name = node.attribute("name")

    output = output.strip

    # remove double [[ ]]s from linking images
    if output[0] == "[" && output[-1] == "]"
      output = output[1, output.length - 2]

      # for linking images, the title of the <a> overrides the title of the <img>
      if node.attribute("title")
        output = node.attribute("title").to_s
      end
    end

    # if there is no link text, but a title attr
    if output.empty? && node.attribute("title")
      output = node.attribute("title").to_s
    end

    if href.nil?
      if !name.nil?
        output = "[#{output}]"
      end
    else
      href = href.to_s

      if href != output && href != "mailto:#{output}" &&
          href != "http://#{output}" && href != "https://#{output}"
        if output.empty?
          output = href
        else
          output = "[#{output}](#{href})"
        end
      end
    end

    case next_node_name(node)
      when "h1", "h2", "h3", "h4", "h5", "h6"
        output += "\n"
    end

    output
  end

  def image_text(node)
    if node.attribute("title")
      "[" + node.attribute("title").to_s + "]"
    elsif node.attribute("alt")
      "[" + node.attribute("alt").to_s + "]"
    else
      ""
    end
  end

  def pass_through_html(node)
    node.to_html
  end
end
