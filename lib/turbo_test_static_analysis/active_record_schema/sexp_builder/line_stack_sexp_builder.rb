# frozen_string_literal: true

require "ripper"

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      class LineStackSexpBuilder < Ripper::SexpBuilder
        EVENTS_TO_REJECT = [:magic_comment].freeze

        ARITIES = ["()", "(a)", "(a,b)", "(a,b,c)", "(a,b,c,d)",
                   "(a,b,c,d,e)", "(a,b,c,d,e,f)", "(a,b,c,d,e,f,g)",
                   "(a,b,c,d,e,f,g,h)"].freeze

        Ripper::PARSER_EVENT_TABLE.each do |method, arity|
          next if EVENTS_TO_REJECT.include?(method)

          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def on_#{method}#{ARITIES[arity]}
              super.tap do |result|
                stack_line
              end
            end
          RUBY
        end

        attr_reader :stack

        def initialize(path, filename = "-", lineno = 1)
          super
          @stack = LineColumnStack.new
        end

        def stack_line
          @stack.push lineno, column
        end
      end
    end
  end
end
