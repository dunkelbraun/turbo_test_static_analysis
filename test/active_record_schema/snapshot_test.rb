# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord::Snapshot" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord::Snapshot }

  test "members" do
    assert_equal %i[extensions tables], subject.new.members
  end

  test "extensions is an empty hash by default" do
    assert_equal({}, subject.new.extensions)
  end

  test "tables is an empty hash by default" do
    assert_equal({}, subject.new.tables)
  end

  test "initialization" do
    snapshot_data = subject.new({ a: 1, b: 2 }, c: 1, d: 2)
    assert_equal({ a: 1, b: 2 }, snapshot_data.extensions)
    assert_equal({ c: 1, d: 2 }, snapshot_data.tables)
  end
end
