# frozen_string_literal: true

module TurboTest
  module StaticAnalysis
    module ActiveRecord
      class Constructor
        def initialize
          @schema = Snapshot.new
          @fingerprints = {}
        end

        def enable_extension(name, content)
          extensions[name] = Digest::MD5.hexdigest(content)
        end

        def fingerprint(table_name, content)
          @fingerprints[table_name] ||= []
          @fingerprints[table_name] << content
        end

        alias add_index fingerprint
        alias add_foreign_key fingerprint
        alias create_table fingerprint
        alias create_trigger fingerprint

        remove_method :fingerprint

        def snapshot
          add_fingerprints
          @schema
        end

        private

        def extensions
          @schema[:extensions]
        end

        def tables
          @schema[:tables]
        end

        def add_fingerprints
          @fingerprints.each_pair.each_with_object(tables) do |(key, val), memo|
            memo[key] = Digest::MD5.hexdigest(val.sort.join)
          end
        end
      end
    end
  end
end
