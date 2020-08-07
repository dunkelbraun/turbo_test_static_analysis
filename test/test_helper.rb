# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

if RUBY_VERSION >= "2.7"
  require "simplecov"
  SimpleCov.start do
    add_filter "/test/"
    enable_coverage :branch unless ENV["CI"]
    minimum_coverage line: 100, branch: 100 unless ENV["CI"]
  end
end

require "turbo_test_static_analysis"
require "minitest/autorun"
require "mocha/minitest"
require "byebug"

class Minitest::Spec
  before do
    FileUtils.mkdir_p "tmp"
  end

  after do
    FileUtils.rm_rf "tmp"
  end
end

module Minitest::Spec::DSL
  alias test it
end
