module Grut
  module Concerns
    module DBTables
      private

      def roles_table
        @roles_table ||= Grut::Config.instance.db_tables[:roles]
      end

      def permissions_table
        @permissions_table ||= Grut::Config.instance.db_tables[:permissions]
      end

      def permission_params_table
        @permission_params_table ||= Grut::Config.instance.db_tables[:permission_params]
      end
    end
  end
end
