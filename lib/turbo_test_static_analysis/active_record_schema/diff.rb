# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      Diff = Struct.new(:changed, :added, :deleted) do
        def initialize(*)
          super
          self.changed ||= []
          self.added ||= []
          self.deleted ||= []
        end
      end
    end
  end
end
