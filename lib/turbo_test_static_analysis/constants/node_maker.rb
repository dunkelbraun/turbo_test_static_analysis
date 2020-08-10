# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module Constants
      module NodeMaker
        private

        def create_top_singleton_class_node(token)
          parent = new_node_from_token(token[1], [lineno, column])
          @class_nodes.push parent
          node = Node.new(
            name: "singleton_class",
            start_pos: node_start_pos(token),
            end_pos: [lineno, column]
          )
          parent.add_child node
          node
        end

        def create_var_ref_singleton_class_node(token)
          node = new_node_from_token(token[1], [lineno, column], singleton_class: true)
          @class_nodes.push node
          child = Node.new(
            name: "singleton_class",
            start_pos: node_start_pos(token),
            end_pos: [lineno, column]
          )
          node.add_child child
          node
        end

        def create_singleton_class_node(token)
          new_node_from_token(token[1], [lineno, column], singleton_class: true)
        end

        def create_singleton_method_definition_with_self_node(token)
          node = Node.new(
            name: "self",
            start_pos: node_start_pos(token),
            end_pos: [lineno, column], definition: true
          )
          @class_nodes.push node
          @all_nodes.unshift(node)
        end

        def create_singleton_method_definition_with_constant_node(token)
          Node.new(
            name: token[1][1],
            start_pos: node_start_pos(token),
            end_pos: [lineno, column],
            definition: true
          )
        end

        def add_block_node(token)
          return unless (start_pos = token[1][3]&.last)

          node = Node.new(
            name: "block",
            start_pos: start_pos,
            end_pos: [lineno, column]
          )
          @block_nodes << node
        end

        def find_or_new_node_for_const_class_or_module_eval(token)
          start_pos = token[1][1][1]
          end_pos = token[1][1][2]
          find_and_update_node([nil, [nil, start_pos, end_pos]]).tap do |node|
            break const_class_or_module_eval_node(start_pos, end_pos) if node.nil?
          end
        end

        def const_class_or_module_eval_node(start_pos, end_pos)
          Node.new(
            name: start_pos,
            start_pos: end_pos,
            end_pos: [lineno, column],
            definition: true
          )
        end

        def ident_class_or_module_eval_node(token)
          Node.new(
            name: token[1][1][1],
            start_pos: token[1][1][2],
            end_pos: [lineno, column],
            definition: true
          )
        end

        def new_node_from_token(token, end_pos = [0, 0], singleton_class: false)
          name = node_name(token)
          start_pos = node_start_pos(token)
          Node.new(name: name, start_pos: start_pos, end_pos: end_pos, singleton: singleton_class)
        end

        def node_name(token)
          case token[0]
          when :@kw
            "singleton_class"
          when :@const
            token[1]
          else
            "unknown_ref"
          end
        end

        def node_start_pos(token)
          start_pos = token.last
          start_pos = start_pos.last while start_pos.last.is_a?(Array)
          start_pos
        end
      end
    end
  end
end
