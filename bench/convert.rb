# frozen_string_literal: true

# Usage: bundle exec ruby bench/convert.rb
#
# Compare branches by running it on each. The sibling divs case guards against
# the quadratic slowdown fixed in #45.

require 'benchmark/ips'
require_relative '../lib/html2text'

examples = Dir[File.join(__dir__, '../spec/examples/*.html')].map { |f| File.read(f) }
sibling_divs = "<div>#{'<div>x</div>' * 2000}</div>"

Benchmark.ips do |x|
  x.report('all spec examples') { examples.each { |html| Html2Text.convert(html) } }
  x.report('2000 sibling divs') { Html2Text.convert(sibling_divs) }
end
