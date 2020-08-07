# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord::Constructor" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord::Constructor }

  test "enable extension" do
    schema_definition = subject.new
    schema_definition.enable_extension "extension_1", "content_1"
    schema_definition.enable_extension "extension_2", "content_2"

    assert_equal 2, schema_definition.snapshot.extensions.length

    assert_equal "71481dd465b70694485a471cfd086f79",
                 schema_definition.snapshot.extensions["extension_1"]

    assert_equal "5314f47c499a746bb1b15a70764e3857",
                 schema_definition.snapshot.extensions["extension_2"]
  end

  test "add index to a table" do
    schema_definition = subject.new
    schema_definition.add_index "table_1", "content_1"
    assert_equal 1, schema_definition.snapshot.tables.length

    assert_equal "71481dd465b70694485a471cfd086f79",
                 schema_definition.snapshot.tables["table_1"]
  end

  test "add a foreign key to a table" do
    schema_definition = subject.new
    schema_definition.add_foreign_key "table_1", "foreign_key"
    assert_equal 1, schema_definition.snapshot.tables.length

    assert_equal "4971f5cf35cd354947b87d70627b4e7d",
                 schema_definition.snapshot.tables["table_1"]
  end

  test "create table to a table" do
    schema_definition = subject.new
    schema_definition.create_table "table_1", "table"
    assert_equal 1, schema_definition.snapshot.tables.length

    assert_equal "aab9e1de16f38176f86d7a92ba337a8d",
                 schema_definition.snapshot.tables["table_1"]
  end

  test "create trigger to a table" do
    schema_definition = subject.new
    schema_definition.create_trigger "table_1", "trigger"
    assert_equal 1, schema_definition.snapshot.tables.length

    assert_equal "c7d08e09a44d2b453e7eeecebf0a8daf",
                 schema_definition.snapshot.tables["table_1"]
  end

  test "add multiple schema schema definitions to a table" do
    schema_definition = subject.new
    schema_definition.add_index "table_1", "content_1"
    schema_definition.add_foreign_key "table_1", "foreign_key"
    schema_definition.create_table "table_1", "table"
    schema_definition.create_trigger "table_1", "trigger"

    assert_equal "f4ccc0b77ee8a367029da204f960f0e3",
                 schema_definition.snapshot.tables["table_1"]
  end
end
