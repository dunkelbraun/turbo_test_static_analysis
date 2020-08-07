# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::ActiveRecord::SexpBuilder" do
  let(:subject) { TurboTest::StaticAnalysis::ActiveRecord::SexpBuilder }
  let(:schema_one) { File.read File.join(Dir.pwd, "test/support/files/schemas/schema1.rb") }

  test "snapshot keys" do
    builder = subject.new schema_one, "db/schema.rb"
    builder.parse
    assert_equal 2, builder.snapshot.extensions.keys.length
  end
  test "extensions snapshot" do
    builder = subject.new schema_one, "db/schema.rb"
    builder.parse

    assert_equal "91e8e97be17631411626e2e99b77863d",
                 builder.snapshot.extensions["plpgsql"]

    assert_equal "f23df82e9ec25464253e1b97166af99c",
                 builder.snapshot.extensions["btree_gin"]
  end

  test "tables snapshot" do
    builder = subject.new schema_one, "db/schema.rb"
    builder.parse

    assert_equal "c5c9966153309edd1b48c53eb62c79ad",
                 builder.snapshot.tables["admins"]

    assert_equal "8b62ba9df4cb900b39260333b3187c6e",
                 builder.snapshot.tables["profiles"]

    assert_equal "a6ef5838e437857440566821512612e1",
                 builder.snapshot.tables["users"]
  end

  test "snapshot from file" do
    file = File.join(Dir.pwd, "test/support/files/schemas/schema1.rb")
    snapshot = subject.snapshot_from_file(file)

    assert_equal 2, snapshot.extensions.keys.length
    assert_equal "91e8e97be17631411626e2e99b77863d", snapshot.extensions["plpgsql"]
    assert_equal "f23df82e9ec25464253e1b97166af99c", snapshot.extensions["btree_gin"]
    assert_equal "c5c9966153309edd1b48c53eb62c79ad", snapshot.tables["admins"]
    assert_equal "8b62ba9df4cb900b39260333b3187c6e", snapshot.tables["profiles"]
    assert_equal "a6ef5838e437857440566821512612e1", snapshot.tables["users"]
  end

  test "snapshot from file with not related code" do
    file = File.join(Dir.pwd, "test/support/files/schemas/schema2.rb")
    snapshot = subject.snapshot_from_file(file)

    assert_equal 3, snapshot.extensions.keys.length
    assert_equal "91e8e97be17631411626e2e99b77863d", snapshot.extensions["plpgsql"]
    assert_equal "f23df82e9ec25464253e1b97166af99c", snapshot.extensions["btree_gin"]
    assert_equal "a7797770b751629c0f585cf6995ddb1e", snapshot.extensions["some_extension"]
    assert_equal "c5c9966153309edd1b48c53eb62c79ad", snapshot.tables["admins"]
    assert_equal "3f3364df87fd9cee15ea88f9dbb75714", snapshot.tables["profiles"]
    assert_equal "228588e9b64f59035cefeb4c1494858b", snapshot.tables["users"]
  end
end
