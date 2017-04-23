require 'sequel'

DB = Sequel.sqlite

DB.create_table :roles do
  primary_key :id
  Integer :user_id, index: true
  String :name, index: true # TODO: add uniq index for [user_id + name]
end

DB.create_table :permissions do
  primary_key :id
  Integer :role_id, index: true
  String :name, index: true # TODO: add uniq index for [role_id + name]
end

DB.create_table :permission_params do
  primary_key :id
  Integer :permission_id
  String :key, index: true
  String :value, index: true # TODO: add uniq index for [permission_id + name + value]
end
