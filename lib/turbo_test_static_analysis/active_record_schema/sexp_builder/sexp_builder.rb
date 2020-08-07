# frozen_string_literal: true

require "digest"
require "sorcerer"
require_relative "line_stack_sexp_builder"

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      class SexpBuilder < LineStackSexpBuilder
        COMMANDS = %w[add_index add_foreign_key enable_extension].freeze
        TABLE_REGEXP = /create_table\s"(\w+)"/.freeze
        TRIGGER_REGEXP = /create_trigger\("(\w+)".+on\("(\w+)"/.freeze
        COMMAND_REGEXP = /\b(\w+)\b/.freeze

        attr_accessor :schema

        def initialize(path, filename = "-", lineno = 1)
          super
          @schema_file = path.split("\n")
          @schema = Constructor.new
        end

        def self.snapshot_from_file(path)
          builder = new(File.read(path), path)
          builder.parse
          builder.snapshot
        end

        def self.snapshot_from_source(source)
          builder = new(source)
          builder.parse
          builder.snapshot
        end

        def snapshot
          @schema.snapshot
        end

        def on_command(token_one, token_two)
          super.tap do |_result|
            name = token_one[1]
            next unless COMMANDS.include? name

            last_line = @stack.remove_greater_than([lineno, column])
            content = method_content(lineno, last_line[0])
            @schema.send(name.to_sym, table_name(:command, token_two), content)
          end
        end

        def on_method_add_block(token_one, token_two)
          super.tap do |_result|
            next unless (type = type_for_token(token_one[0]))

            first_line, last_line = send("#{type}_lines", token_one)
            handle_create(type, token_one, first_line, last_line)
          end
        end

        private

        def type_for_token(token)
          case token
          when :command
            :table
          when :method_add_arg
            :trigger
          end
        end

        def table_lines(token)
          return unless token[1][1] == "create_table"

          last_line = @stack.remove_greater_than(token[1][2])
          [token[1][2][0], last_line[0]]
        end

        def trigger_lines(token)
          fcall = extract_fcall(token[1])
          return unless fcall[0] == "create_trigger"

          first_line = fcall[1]
          last_line = @stack.remove_greater_than(first_line)
          [first_line[0], last_line[0]]
        end

        def handle_create(type, token, line_start, line_end)
          return unless line_start && line_end

          table = table_name(type, token)
          content = method_content(line_start, line_end)
          @schema.send("create_#{type}".to_sym, table, content)
        end

        def table_name(type, token)
          regexp = self.class.const_get "#{type.upcase}_REGEXP"
          match = Sorcerer.source(token).match(regexp)
          case type
          when :trigger
            match[1..2][1]
          else
            match[1]
          end
        end

        def method_content(start_line, end_line)
          lines_str(start_line, end_line)
        end

        def extract_fcall(token)
          case token[0]
          when :fcall
            [token[1][1], token[1][2]]
          when :call
            extract_fcall(token[1][1])
          else
            []
          end
        end

        def lines_str(from, to)
          from -= 1
          to -= 1
          @schema_file[from..to].join("")
        end
      end
    end
  end
end
