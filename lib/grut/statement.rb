module Grut
  class Statement
    include Concerns::DBTables

    Entry = Struct.new(:role, :permission, :contract_key, :contract_value) do
      def self.from_hash(hash)
        new(*hash.values_at(:role, :permission, :contract_key, :contract_value))
      end
    end

    def initialize(user)
      @user = user
    end

    def all(role: nil, permission: nil, contract: {})
      permission = permission.to_s if permission
      role = role.to_s if role
      contract = Asset.stringify_hash(contract)

      permission_condition = permission ? 'and p.name = :permission' : ''
      role_condition = role ? 'and r.name = :role' : ''
      contract_condition = contract.any? ? "and #{Asset.contract_sql_condition(contract)}" : ''

      args = Asset.sanitize_contract_hash(contract).merge(user_id: @user.id, role: role, permission: permission)
      deserialize(DB.conn[<<-SQL, args].map { |args| Entry.from_hash(args) })
        select r.name as role, p.name as permission, pp.key as contract_key, pp.value as contract_value from #{roles_table} r
          join #{permissions_table} p on p.role_id = r.id #{permission_condition}
            join #{permission_params_table} pp on pp.permission_id = p.id #{contract_condition}
          where r.user_id = :user_id #{role_condition}
      SQL
    end

    private

    def deserialize(ary)
      ary.each do |e|
        deserialized_value = YAML.load(e.contract_value)
        next unless deserialized_value.is_a?(Hash)
        e.contract_value = deserialized_value
      end
      ary
    end
  end
end
