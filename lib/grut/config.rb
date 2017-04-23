require 'singleton'

module Grut
  class Config
    include Singleton

    attr_accessor :db_url

    def db_tables
      @tables ||= {
        roles: :grut_roles,
        permissions: :grut_permissions,
        permission_params: :grut_permission_params
      }
    end
  end
end
