namespace :grut do
  task :config do
    require 'yaml'
    env = ENV['ENV'] || ENV['RAILS_ENV'] || 'development'
    config_file = nil
    config_file ||= 'config/grut_database.yml' if File.exists?('config/grut_database.yml')
    config_file ||= 'config/database.yml' if File.exists?('config/database.yml')
    fail 'Config file not found' unless config_file
    Grut::Config.instance.db_url ||= YAML.load_file(config_file)[env]
  end

  desc 'Create necessary tables in the DB, specified by a config'
  task :install => :config do
    DB.conn.create_table Grut::Config.instance.db_tables[:roles] do
      primary_key :id
      Integer :user_id, null: false
      String :name, null: false
      index [:user_id, :name], unique: true, name: :grut_uniq_name_on_user_id_index
    end

    DB.conn.create_table Grut::Config.instance.db_tables[:permissions] do
      primary_key :id
      foreign_key :role_id, Grut::Config.instance.db_tables[:roles], null: false
      String :name, null: false
      index [:role_id, :name], unique: true, name: :grut_uniq_name_on_role_id_index
    end

    DB.conn.create_table Grut::Config.instance.db_tables[:permission_params] do
      primary_key :id
      foreign_key :permission_id, Grut::Config.instance.db_tables[:permissions], null: false
      String :key, index: true, null: false
      String :value, index: true, null: false
    end
  end

  desc 'Deletes all created tables in the DB'
  task :remove => :config do
    DB.conn.run(<<-SQL)
      drop table if exists #{Grut::Config.instance.db_tables[:permission_params]};
      drop table if exists #{Grut::Config.instance.db_tables[:permissions]};
      drop table if exists #{Grut::Config.instance.db_tables[:roles]};
    SQL
  end
end
