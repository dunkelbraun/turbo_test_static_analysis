# frozen_string_literal: true

require "ripper"
require_relative "node"
require_relative "token_matcher"
require_relative "node_maker"
require_relative "node_processor"

module TurboTest
  module StaticAnalysis
    module Constants
      class SexpBuilder < Ripper::SexpBuilder
        attr_reader :defined_classes, :referenced_top_constants, :referenced_constants

        include TokenMatcher
        include NodeMaker
        include NodeProcessor

        def initialize(path, filename = "-", lineno = 1)
          @const_refs = {}
          @referenced_top_constants = {}
          @referenced_constants = {}
          @class_nodes = []
          @defined_classes = []
          @all_nodes = []
          @var_refs = []
          @block_nodes = []
          super
        end

        def on_sclass(token_one, token_two)
          node = if top_const_ref?(token_one)
                   create_top_singleton_class_node(token_one)
                 elsif var_ref?(token_one)
                   create_var_ref_singleton_class_node(token_one)
                 else
                   create_singleton_class_node(token_one)
                 end
          process_module(node)
          @all_nodes.shift if top_const_ref?(token_one)
          super
        end

        def on_module(token_one, token_two, token_three = nil)
          process_module find_and_update_node(token_one)
          super
        end
        alias on_class on_module

        def on_defs(token_one, token_two, token_three, token_four, token_five)
          if singleton_method_definition_with_self?(token_one)
            create_singleton_method_definition_with_self_node(token_one)
          elsif singleton_method_definition_with_constant?(token_one)
            node = create_singleton_method_definition_with_constant_node(token_one)
            process_module(node)
          end
          super
        end

        def on_top_const_ref(token)
          add_const_ref token, top_level: true
          add_referenced_top_constant token[1]
          super
        end

        def on_const_ref(token)
          add_const_ref token
          super
        end

        def on_var_ref(token)
          @var_refs << new_node_from_token(token, [lineno, column]) if token[0] == :@const
          super
        end
        alias on_var_field on_var_ref

        def on_top_const_field(token)
          add_referenced_top_constant token[1]
          super
        end

        def on_def(token_one, token_two, token_three)
          super
        end

        def on_method_add_block(token_one, token_two)
          add_block_node(token_one)
          if const_class_or_module_eval?(token_one)
            node = find_or_new_node_for_const_class_or_module_eval(token_one)
            process_module node
          elsif ident_class_or_module_eval?(token_one)
            node = ident_class_or_module_eval_node(token_one)
            reject_children_in_class_nodes(node)
          end
          super
        end

        def on_program(token_one)
          process_class_nodes
          process_var_refs
          reject_unknown_constants
          super
        end
      end
    end
  end
end

# Check https://fili.pp.ru/leaky-constants.html
