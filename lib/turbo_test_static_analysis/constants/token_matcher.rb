# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module Constants
      module TokenMatcher
        private

        def top_const_ref?(token)
          token[0] == :top_const_ref
        end

        def var_ref?(token)
          token[0] == :var_ref
        end

        def const_class_or_module_eval?(token)
          token.last[0] == :@ident &&
            %w[class_eval module_eval].include?(token.last[1]) &&
            token[1][1][0] == :@const
        end

        def ident_class_or_module_eval?(token)
          token.last[0] == :@ident &&
            %w[class_eval module_eval].include?(token.last[1]) &&
            token[1][1][0] == :@ident
        end

        def singleton_method_definition_with_self?(token)
          token[1] &&
            token[1][0] == :@kw &&
            token[1][1] == "self"
        end

        def singleton_method_definition_with_constant?(token)
          token[0] == :var_ref &&
            token[1] &&
            token[1][0] == :@const
        end
      end
    end
  end
end
