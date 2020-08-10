# frozen_string_literal: true

require "test_helper"

describe "TurboTest::StaticAnalysis::Constants::Node" do
  test "has a name" do
    node = node_class.new(name: "test-node", start_pos: [1, 1], end_pos: [1, 20])
    assert_equal "test-node", node.name
  end

  describe "full name" do
    test "full name for a node without parent" do
      node = node_class.new(name: "test-node", start_pos: [2, 1], end_pos: [2, 20])
      assert_equal "test-node", node.full_name
    end

    test "full name include the names of its parent" do
      node = node_class.new(name: "node", start_pos: [5, 1], end_pos: [5, 20])
      parent = node_class.new(name: "parent", start_pos: [4, 1], end_pos: [6, 20])
      parent.add_child(node)
      parent_parent = node_class.new(name: "parent-parent", start_pos: [2, 1], end_pos: [7, 20])
      parent_parent.add_child(parent)
      assert_equal "parent-parent::parent::node", node.full_name
    end
  end

  test "can have children" do
    node = node_class.new(name: "test-node", start_pos: [1, 1], end_pos: [6, 20])
    refute node.children.any?
    child_one = node_class.new(name: "child-1", start_pos: [2, 1], end_pos: [2, 29])
    child_two = node_class.new(name: "child-2", start_pos: [3, 1], end_pos: [3, 20])
    node.add_child child_one
    node.add_child child_two
    assert_equal [child_one, child_two], node.children
    assert node, child_one.parent
    assert node, child_two.parent
  end

  test "a child needs to be contained in the node" do
    node = node_class.new(name: "test-node", start_pos: [1, 1], end_pos: [6, 20])
    refute node.children.any?
    child_one = node_class.new(name: "child-1", start_pos: [2, 1], end_pos: [2, 29])
    another_node = node_class.new(name: "child-2", start_pos: [20, 1], end_pos: [23, 20])
    node.add_child child_one
    node.add_child another_node
    assert_equal [child_one], node.children
    assert node, child_one.parent
    assert_nil another_node.parent
  end

  describe "#contains?" do
    test "contains another node if starts before and ends after another node" do
      node = node_class.new(name: "node1", start_pos: [2, 1], end_pos: [5, 20])
      another_node = node_class.new(name: "node2", start_pos: [2, 2], end_pos: [4, 14])
      assert node.contains?(another_node)
      refute another_node.contains?(node)

      # Node starts before and ends before
      # Node starts after and ends after
      node = node_class.new(name: "node1", start_pos: [2, 1], end_pos: [5, 20])
      another_node = node_class.new(name: "node2", start_pos: [6, 2], end_pos: [6, 14])
      refute node.contains?(another_node)
      refute another_node.contains?(node)

      # Node starts before and ends same
      # Node starts after and ends same
      node = node_class.new(name: "node1", start_pos: [2, 1], end_pos: [5, 20])
      another_node = node_class.new(name: "node2", start_pos: [6, 2], end_pos: [5, 20])
      refute node.contains?(another_node)
      refute another_node.contains?(node)
    end

    test "contains another node if starts and ends the same as other node" do
      node = node_class.new(name: "node1", start_pos: [2, 1], end_pos: [5, 20])
      another_node = node_class.new(name: "node2", start_pos: [2, 1], end_pos: [5, 20])
      assert node.contains?(another_node)
      assert another_node.contains?(node)
    end
  end

  private

  def node_class
    TurboTest::StaticAnalysis::Constants::Node
  end
end
