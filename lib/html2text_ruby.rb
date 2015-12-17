require 'nokogiri'

class Html2Text
  attr_reader :doc

  def initialize(doc)
    @doc = doc
  end

  def self.convert(html)
    doc = Nokogiri::HTML(html)

    Html2Text.new(doc).convert
  end

  def convert
    output = iterate_over doc
    output = remove_leading_and_trailing_whitespace(output)
    output.strip
  end

  def remove_leading_and_trailing_whitespace(text)
    text.gsub(/[ \t]*\n[ \t]*/im, "\n")
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

    next_node = next_node_name(node)

    output = []

    # start whitespace
    output << case node.name.downcase
      when "hr"
        return "------\n"

      when "style", "head", "title", "meta", "script"
        # ignore these tags
        return "";

      when "h1", "h2", "h3", "h4", "h5", "h6", "ol", "ol"
        "\n"

      when "tr", "p", "div"
        "\n"
    end

    # add all child content
    output += node.children.map do |child|
      iterate_over(child)
    end

    # end whitespace
    output << case node.name.downcase
      when "h1", "h2", "h3", "h4", "h5", "h6"
        # add another line
        "\n"

      when "p", "br"
        "\n" if next_node != "div"

      when "div"
        # add one line only if the next child isn't a div
        "\n" if next_node != "div" && next_node != nil
    end

    output = output.compact.join("") || ""

    if node.name.downcase == "a"
      output = wrap_link(node, output)
    end

    output
  end

  # links are returned in [text](link) format
  def wrap_link(node, output)
    href = node.attribute("href")
    name = node.attribute("name")

    if href.nil?
      "[#{output}]"
    else
      "[#{output}](#{href})"
    end
  end
end
