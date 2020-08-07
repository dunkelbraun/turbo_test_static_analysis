# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord#schema_changes" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord }

  describe "extensions" do
    it "detects added extensions" do
      schema_changes = subject.schema_changes read_schema("extension2"), read_schema("extension1")
      assert_equal ["some_extension"], schema_changes[:extensions][:added]
      assert schema_changes[:extensions][:changed].empty?
      assert schema_changes[:extensions][:deleted].empty?
    end

    it "detects deleted extensions" do
      schema_changes = subject.schema_changes read_schema("extension1"), read_schema("extension2")
      assert_equal ["some_extension"], schema_changes[:extensions][:deleted]
      assert schema_changes[:extensions][:added].empty?
      assert schema_changes[:extensions][:changed].empty?
    end
  end

  describe "tables" do
    it "detects added tables" do
      schema_changes = subject.schema_changes read_schema("table"), read_schema("no_table")
      assert_equal %w[admins users], schema_changes[:tables][:added]
      assert schema_changes[:tables][:changed].empty?
      assert schema_changes[:tables][:deleted].empty?
    end

    it "detects deleted tables" do
      schema_changes = subject.schema_changes read_schema("no_table"), read_schema("table")
      assert_equal %w[admins users], schema_changes[:tables][:deleted]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:changed].empty?
    end
  end

  describe "table columns" do
    it "detects modified columns" do
      schema_changes = subject.schema_changes read_schema("table"),
                                              read_schema("table_column_change")
      assert_equal %w[admins users], schema_changes[:tables][:changed]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:deleted].empty?
    end

    it "detects added columns" do
      schema_changes = subject.schema_changes read_schema("table"),
                                              read_schema("table_column_add")
      assert_equal %w[admins users], schema_changes[:tables][:changed]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:deleted].empty?
    end

    it "detects deleted columns" do
      schema_changes = subject.schema_changes read_schema("table"),
                                              read_schema("table_column_delete")
      assert_equal %w[admins users], schema_changes[:tables][:changed]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:deleted].empty?
    end
  end

  describe "table indexes" do
    it "detects added indexes" do
      schema_changes = subject.schema_changes read_schema("table"),
                                              read_schema("table_index_add")
      assert_equal %w[admins users], schema_changes[:tables][:changed]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:deleted].empty?
    end

    it "detects changed indexes" do
      schema_changes = subject.schema_changes read_schema("table"),
                                              read_schema("table_index_change")
      assert_equal %w[admins users], schema_changes[:tables][:changed]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:deleted].empty?
    end

    it "detects deleted indexes" do
      schema_changes = subject.schema_changes read_schema("table"),
                                              read_schema("table_index_delete")
      assert_equal %w[admins users], schema_changes[:tables][:changed]
      assert schema_changes[:tables][:added].empty?
      assert schema_changes[:tables][:deleted].empty?
    end
  end

  def read_schema(name)
    File.read File.join(Dir.pwd, "test/support/files/schemas/#{name}.rb")
  end
end
