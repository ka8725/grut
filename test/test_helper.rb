$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'pry-byebug'
require 'grut'
require 'minitest/autorun'

User = Struct.new(:id)

module TestsHelper
  def self.clean_db
    DB.conn.run(<<-SQL)
      delete from #{Grut::Config.instance.db_tables[:permission_params]};
      delete from #{Grut::Config.instance.db_tables[:permissions]};
      delete from #{Grut::Config.instance.db_tables[:roles]};
    SQL
  end
end

Rake::Task['grut:config'].invoke
