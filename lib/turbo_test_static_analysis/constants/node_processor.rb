# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module Constants
      module NodeProcessor
        private

        def node_key(token)
          "#{token[1]}-#{token[2].join('-')}"
        end

        def process_module(node)
          @var_refs.reject! do |var_ref|
            (var_ref.name == node.name && var_ref.start_pos == node.start_pos) ||
              node.contains?(var_ref).tap do |condition|
                @referenced_constants[var_ref.name] = true if condition
              end
          end
          @class_nodes.push node
          assign_children(node)
        end

        def process_class_nodes
          @class_nodes.reject! do |class_node|
            next process_definition_class_node(class_node) if class_node.root.definition

            @referenced_constants[class_node.name] = true if class_node.named_singleton_with_parent?
            class_node.parent_is_named_singleton? || class_node.named_singleton_with_parent?
          end

          @defined_classes = class_nodes_names_without_singletons_and_unknowns
        end

        def process_definition_class_node(node)
          container_node = @class_nodes.find do |class_node|
            class_node != node.root && class_node.contains?(node.root)
          end
          return false if container_node.nil?

          @referenced_constants[node.full_name] = true if node.name != "self"
          true
        end

        def process_var_refs
          @var_refs.each do |var_ref|
            if @block_nodes.find { |node| node.contains?(var_ref) }
              @referenced_constants[var_ref.name] = true
            else
              @referenced_top_constants[var_ref.name] = true
            end
          end
        end

        def class_nodes_names_without_singletons_and_unknowns
          @class_nodes.map(&:full_name).reject do |full_name|
            full_name.end_with?("singleton_class") || full_name.include?("unknown_ref")
          end.uniq
        end

        def reject_unknown_constants
          @referenced_top_constants.reject! do |key, _value|
            key.include?("unknown_ref")
          end

          @referenced_constants.reject! do |key, _value|
            key.include?("unknown_ref")
          end
        end

        def assign_children(node)
          if @referenced_top_constants.delete(node.name)
            @all_nodes.unshift(node)
            add_children(node)
          else
            add_children(node)
            @all_nodes.unshift(node)
          end
        end

        def add_children(node)
          @all_nodes.reject! do |children_candidate|
            node.contains?(children_candidate).tap do |child|
              node.add_child(children_candidate) if child && children_candidate.definition == false
            end
          end
        end

        def add_const_ref(token, top_level: false)
          node = new_node_from_token(token)
          node.top_level = top_level
          @const_refs[node_key(token)] = node
        end

        def add_referenced_top_constant(name)
          @referenced_top_constants[name] = true
        end

        def find_and_update_node(token)
          @const_refs.delete(node_key(token[1])).tap do |node|
            node.end_pos = [lineno, column] if node
          end
        end

        def reject_children_in_class_nodes(node)
          @class_nodes.reject! do |class_node|
            node.contains?(class_node).tap do |child|
              @referenced_constants[class_node.full_name] = true if child
            end
          end
        end
      end
    end
  end
end
