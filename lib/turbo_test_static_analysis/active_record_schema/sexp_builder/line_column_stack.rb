# frozen_string_literal: true

require "forwardable"

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      class LineColumnStack
        extend Forwardable

        def_delegators :@_stack, :pop, :last, :any?

        def initialize
          @_stack = []
        end

        def push(line, column)
          line_column = [line, column]
          @_stack.push line_column unless @_stack.last == line_column
        end

        def remove_greater_than(line_column)
          first_pop = nil
          while last && greater(last, line_column)
            line = pop
            first_pop ||= line
          end
          first_pop
        end

        private

        def greater(line_column_a, line_column_b)
          line_column_a[0] > line_column_b[0] ||
            (line_column_a[0] == line_column_b[0] &&
              line_column_a[1] >= line_column_b[1])
        end
      end
    end
  end
end
