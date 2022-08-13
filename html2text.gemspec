$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "html2text/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "html2text"
  s.version     = Html2Text::VERSION
  s.authors     = ["Jevon Wright"]
  s.email       = ["jevon@jevon.org"]
  s.homepage    = "https://github.com/soundasleep/html2text_ruby"
  s.summary     = "Convert HTML into plain text."
  s.description = "A Ruby component to convert HTML into a plain text format."
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "LICENSE.md", "README.md", "CHANGELOG.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "nokogiri", ">= 1.13.6"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rspec-collection_matchers"
  s.add_development_dependency "colorize"
  s.add_development_dependency "rake"
  s.add_development_dependency "bundler-audit"
end
