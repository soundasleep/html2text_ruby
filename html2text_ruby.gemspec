$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "html2text_ruby/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "html2text_ruby"
  s.version     = Html2Text::VERSION
  s.authors     = ["Jevon Wright"]
  s.email       = ["jevon@powershop.co.nz"]
  s.homepage    = "https://github.com/soundasleep/html2text-ruby"
  s.summary     = "Convert HTML into plain text."
  s.description = "A Ruby component to convert HTML into a plain text format."
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "nokogiri", "~> 1.6"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-collection_matchers"
  s.add_development_dependency "colorize"
  s.add_development_dependency "rake"
end
