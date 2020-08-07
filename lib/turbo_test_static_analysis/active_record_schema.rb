# frozen_string_literal: true

require_relative "active_record_schema/diff"
require_relative "active_record_schema/map"
require_relative "active_record_schema/snapshot"
require_relative "active_record_schema/diff_compute"
require_relative "active_record_schema/constructor"
require_relative "active_record_schema/sexp_builder/line_column_stack"
require_relative "active_record_schema/sexp_builder/sexp_builder"
require_relative "active_record_schema/sexp_builder/line_stack_sexp_builder"

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      class << self
        def schema_changes(new_schema, old_schema)
          current_snapshot = SexpBuilder.snapshot_from_source(new_schema)
          previous_snapshot = SexpBuilder.snapshot_from_source(old_schema)
          changes = DiffCompute.new(current_snapshot, previous_snapshot).calc
          {
            extensions: changes[:extensions].to_h,
            tables: changes[:tables].to_h
          }
        end
      end
    end
  end
end
