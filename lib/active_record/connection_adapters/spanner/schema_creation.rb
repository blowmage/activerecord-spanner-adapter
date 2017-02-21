module ActiveRecord
  module ConnectionAdapters
    module Spanner
      class DDL < String; end

      class SchemaCreation < AbstractAdapter::SchemaCreation
        def visit_TableDefinition(o)
          DDL.new(super)
        end
      end
    end
  end
end

