# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      Map = Struct.new(:extensions, :tables) do
        def initialize(*)
          super
          self.extensions ||= []
          self.tables ||= []
        end
      end
    end
  end
end
