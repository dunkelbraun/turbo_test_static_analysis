# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord::SchemaMap" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord::Map.new }

  test "members" do
    assert_equal %i[extensions tables], subject.members
  end

  test "extensions is an empty array by default" do
    assert_equal [], subject.extensions
  end

  test "tables is an empty array by default" do
    assert_equal [], subject.tables
  end
end
