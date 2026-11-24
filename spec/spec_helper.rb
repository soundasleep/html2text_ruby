# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  add_filter '/spec/'
  minimum_coverage line: 100, branch: 100
end

require 'rspec'
require 'rspec/collection_matchers'

require File.join(File.dirname(__FILE__), '..', 'lib', 'html2text')
