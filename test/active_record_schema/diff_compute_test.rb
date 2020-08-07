# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord::DiffCompute" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord::DiffCompute }

  test "calculate diff between two schema maps for added extensions" do
    computed = klass.new(schema_one_snapshot, schema_two_snapshot).calc
    assert_equal ["btree_gin"], computed[:extensions].added
  end

  test "calculate diff between two schema maps for deleted extensions" do
    computed = klass.new(schema_one_snapshot, schema_two_snapshot).calc
    assert_equal ["plpgsqel"], computed[:extensions].deleted
  end

  test "calculate diff between two schema maps for added tables" do
    computed = klass.new(schema_one_snapshot, schema_two_snapshot).calc
    assert_equal ["table_4"], computed[:tables].added
  end

  test "calculcate diff between two schema maps for changed tables" do
    computed = klass.new(schema_one_snapshot, schema_two_snapshot).calc
    assert_equal %w[table_1 table_3], computed[:tables].changed
  end

  test "calculcate diff between two schema maps for deleted tables" do
    computed = klass.new(schema_one_snapshot, schema_two_snapshot).calc
    assert_equal ["table_5"], computed[:tables].deleted
  end

  private

  def klass
    TurboTest::StaticAnalysis::ActiveRecord::DiffCompute
  end

  def schema_one_snapshot
    extensions = {
      "btree_gin" => "fingerprint_2",
      "btree_gist" => "fingerprint_3"
    }
    tables = {
      "table_1" => "fingerprint_41",
      "table_2" => "fingerprint_5",
      "table_3" => "fingerprint_63",
      "table_4" => "fingerprint_7"
    }
    TurboTest::StaticAnalysis::ActiveRecord::Snapshot.new(extensions, tables)
  end

  def schema_two_snapshot
    extensions = {
      "plpgsqel" => "fingerprint_1",
      "btree_gist" => "fingerprint_3"
    }
    tables = {
      "table_1" => "fingerprint_4",
      "table_2" => "fingerprint_5",
      "table_3" => "fingerprint_6",
      "table_5" => "fingerprint_7"
    }
    TurboTest::StaticAnalysis::ActiveRecord::Snapshot.new(extensions, tables)
  end
end
