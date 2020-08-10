# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module Constants
      class Node
        attr_reader :name, :start_pos, :parent, :children, :singleton
        attr_accessor :end_pos, :top_level, :definition

        def initialize(name:, start_pos:, end_pos:, singleton: false, definition: false)
          @name = name
          @children = []
          @start_pos = start_pos
          @end_pos = end_pos
          @parent = nil
          @singleton = singleton
          @definition = definition
          @top_level = false
        end

        def add_child(child)
          return if child.start_pos == start_pos && child.name == name
          return unless contains?(child)

          @children << child
          child.instance_variable_set(:@parent, self)
          child.instance_variable_set(:@definition, definition)
          child
        end

        def contains?(node)
          ((@start_pos <=> node.start_pos) == -1 && (@end_pos <=> node.end_pos) == 1) ||
            ((@start_pos <=> node.start_pos).zero? &&
              ((@end_pos <=> node.end_pos).zero? || (@end_pos <=> node.end_pos) == 1))
        end

        def full_name
          return @name unless @parent

          [@parent.full_name, @name].compact.join("::")
        end

        def root
          return self if parent.nil?

          parent.root
        end

        def parent_is_named_singleton?
          return false unless parent

          parent.singleton && parent.name != "singleton_class"
        end

        def named_singleton_with_parent?
          return false unless parent

          singleton && name != "singleton_class"
        end

        class << self
        end
      end
    end
  end
end
