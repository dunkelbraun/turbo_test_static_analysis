# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord::Diff" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord::Diff.new }

  test "members" do
    assert_equal %i[changed added deleted], subject.members
  end

  test "changed is an empty array by default" do
    assert_equal [], subject.changed
  end

  test "added is an empty array by default" do
    assert_equal [], subject.added
  end

  test "deleted is an empty array by default" do
    assert_equal [], subject.deleted
  end
end
