$:.push File.expand_path("../lib", __FILE__)

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "html2text_ruby"
  s.version     = "0.1.0"
  s.authors     = ["Jevon Wright"]
  s.email       = ["jevon@powershop.co.nz"]
  s.homepage    = "https://github.com/soundasleep/html2text-ruby"
  s.summary     = "Convert HTML into plain text."
  s.description = "A Ruby component to convert HTML into a plain text format."
  s.license     = "MIT"

  s.files = Dir["lib/**/*", "MIT-LICENSE", "README.md"]
  s.test_files = Dir["spec/**/*"]
end
