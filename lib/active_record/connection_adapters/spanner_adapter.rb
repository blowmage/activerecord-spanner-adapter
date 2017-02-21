require 'google/cloud/spanner'

require 'active_record/connection_adapters/abstract_adapter'
require 'active_record/connection_adapters/spanner/schema_creation'
require 'active_record/connection_adapters/spanner/schema_statements'

module ActiveRecord
  module ConnectionHandling
    def spanner_connection(config)
      ConnectionAdapters::SpannerAdapter.new(nil, logger, config)
    end
  end

  module ConnectionAdapters
    # A Google Cloud Spanner adapter
    #
    # Options:
    # - project
    class SpannerAdapter < AbstractAdapter
      ADAPTER_NAME = 'Spanner'.freeze
      CLIENT_PARAMS = [:project, :keyfile, :scope, :timeout, :client_config].freeze
      ADAPTER_OPTS = (CLIENT_PARAMS + [:instance, :database]).freeze

      NATIVE_DATABASE_TYPES = {
        primary_key: 'STRING[36]',
      }

      include Spanner::SchemaStatements


      def initialize(connection, logger, config)
        super(connection, logger, config)
        conn_params = config.symbolize_keys.slice(*ADAPTER_OPTS)
        connect(conn_params)
      end

      def schema_creation # :nodoc:
        Spanner::SchemaCreation.new self
      end

      def active?
        !!@db
        # TODO(yugui) Check db.service.channel.connectivity_state once it is fixed?
      end

      def connect(params)
        client_params = params.slice(*CLIENT_PARAMS)
        client = Google::Cloud::Spanner.new(**client_params)
        @db = client.database(params[:instance], params[:database])
        raise ActiveRecord::ConnectionNotEstablished, 
          "database #{db.database_path} is not ready" unless @db.ready?
      end

      def disconnect!
        invalidate_session
      end

      def execute(stmt)
        case stmt
        when Spanner::DDL
          execute_ddl(stmt)
        else
          super(stmt)
        end
      end

      private
      def session
        @session ||= @db.session
      end

      def invalidate_session
        @session&.delete_session
        @session = nil
      end
    end
  end
end

