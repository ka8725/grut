module Grut
  class Guardian
    def initialize(user, role)
      @user = user
      @role = role.to_s
    end

    def permit(permission, params = {})
      params = stringify_hash(params)
      permission = permission.to_s
      return if role_exists?(permission, params)
      permit_role_with_params(permission, params)
    end

    def permitted?(permission, params = {})
      params = stringify_hash(params)
      permission = permission.to_s
      role_exists?(permission, params)
    end

    private

    def role_exists?(permission, params = {})
      select = DB[<<-SQL, user_id: @user.id, role: @role, permission: permission, key: params.keys.first, value: params.values.first]
        select 1 from roles r
          join permissions p on p.role_id = r.id and p.name = :permission
            join permission_params pp on pp.permission_id = p.id and pp.key = :key and pp.value = :value
          where r.user_id = :user_id and r.name = :role
      SQL
      select.count > 0
    end

    def permit_role_with_params(permission_name, params = {})
      DB.transaction do
        role = DB[:roles].where(user_id: @user.id).first
        role ||= DB[:roles].where(
                   id: DB[:roles].insert(name: @role, user_id: @user.id)
                 ).first

        permission = DB[:permissions].where(role_id: role[:id], name: permission).first
        permission ||= DB[:permissions].where(
                         id: DB[:permissions].insert(role_id: role[:id], name: permission_name)
                       ).first

        permission_param = DB[:permission_params].where(
          permission_id: permission[:id], key: params.keys.first, value: params.values.first
        ).first
        permission_param ||= DB[:permission_params].where(
          id: DB[:permission_params].insert(permission_id: permission[:id], key: params.keys.first, value: params.values.first)
        ).first
      end
    end

    def stringify_hash(params)
      params.reduce({}) do |res, (key, val)|
        res[key.to_s] = val.to_s
        res
      end
    end
  end
end
