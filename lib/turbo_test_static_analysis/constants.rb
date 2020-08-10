# frozen_string_literal: true

require_relative "constants/sexp_builder"

module TurboTest
  module StaticAnalysis
    module Constants
      def self.parse(source)
        SexpBuilder.new(source).tap(&:parse)
      end
    end
  end
end
