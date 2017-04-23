require 'sequel'
require 'singleton'

class DB
  include Singleton

  def self.conn
    instance.conn
  end

  def conn
    @conn ||= Sequel.connect(db_url)
  end

  private

  def db_url
    url = Grut::Config.instance.db_url
    fail 'Database connection is not configured' unless url
    url
  end
end
