# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      class DiffCompute
        def initialize(new_snapshot, old_snapshot)
          @data = { new: new_snapshot, old: old_snapshot }
        end

        def calc
          empty_diff.tap do |diff|
            compute(:extensions, diff[:extensions])
            compute(:tables, diff[:tables])
          end
        end

        private

        def empty_diff
          {
            extensions: Diff.new,
            tables: Diff.new
          }
        end

        def compute(type, diff)
          compute_added_changed type, diff
          compute_deleted type, diff
        end

        def compute_added_changed(type, diff)
          iterator = @data.dig(:new, type).each_pair
          iterator.each_with_object(diff) do |(name, fgpt), memo|
            old_data = @data.dig(:old, type)
            unless old_data[name]
              memo.added << name
              next memo
            end
            memo.changed << name if fgpt != old_data[name]
          end
        end

        def compute_deleted(type, diff)
          @data.dig(:old, type).each_key.each_with_object(diff) do |name, memo|
            memo.deleted << name unless @data.dig(:new, type)[name]
          end
        end
      end
    end
  end
end
