module Grut
  class Guardian
    include Concerns::DBTables

    def initialize(user, role)
      @user = user
      @role = role.to_s
    end

    def permit(permission, params = {})
      params = Asset.stringify_hash(params)
      permission = permission.to_s

      return false if role_exists?(permission, params)
      permit_role_with_params(permission, params)
      true
    end

    def forbid(permission, params = {})
      params = Asset.stringify_hash(params)
      permission = permission.to_s

      forbit_role_with_params(permission, params)
      true
    end

    def permitted?(permission, params = {})
      params = Asset.stringify_hash(params)
      permission = permission.to_s

      role_exists?(permission, params)
    end

    private

    def role_exists?(permission, params)
      params_conditions = Asset.contract_sql_condition(params)
      params = Asset.sanitize_contract_hash(params)
      select = DB.conn[<<-SQL, params.merge(user_id: @user.id, role: @role, permission: permission)]
        select 1 from #{roles_table} r
          join #{permissions_table} p on p.role_id = r.id and (p.name = :permission or p.name = 'manage')
            join #{permission_params_table} pp on pp.permission_id = p.id and (
              (#{params_conditions}) or (key = 'all' and value = 'true')
            )
          where r.user_id = :user_id and r.name = :role and (
            p.name = :permission or (p.name = 'manage' and pp.key = 'all' and pp.value = 'true')
          )
      SQL
      select.count > 0
    end

    def permit_role_with_params(permission_name, params)
      DB.conn.transaction do
        role_id = find_or_create(_Role, user_id: @user.id, name: @role)
        break if role_manages_all?(role_id)
        permission_id = find_or_create(_Permission, role_id: role_id, name: permission_name)
        if params['all'] == 'true'
          _PermissionParam.where(permission_id: permission_id).delete
          find_or_create(_PermissionParam, permission_id: permission_id, key: 'all', value: 'true')
        else
          params.each do |key, value|
            find_or_create(_PermissionParam, permission_id: permission_id, key: key, value: value)
          end
        end
      end
    end

    def forbit_role_with_params(permission_name, params)
      role = _Role[user_id: @user.id] || {}
      permission = _Permission[role_id: role[:id], name: permission_name] || {}
      is_all = params['all'] == 'true'
      permission_params = is_all ? [] : (params.map do |key, val|
        _PermissionParam[permission_id: permission[:id], key: key, value: val]
      end.compact)
      DB.conn.transaction do
        if is_all
          _PermissionParam.where(permission_id: permission[:id]).delete
        else
          _PermissionParam.where(id: permission_params.map { |pp| pp[:id] }).delete
        end
        _Permission.where(id: permission[:id]).delete if _PermissionParam.count(permission_id: permission[:id]) == 0
        _Role.where(id: role[:id]).delete if _Permission.count(role_id: role[:id]) == 0
      end
    end

    def find_or_create(entity, params)
      (entity[params] || {})[:id] || entity.insert(params)
    end

    def role_manages_all?(role_id)
      permission = _Permission[name: 'manage', role_id: role_id]
      return false unless permission
      _PermissionParam[key: 'all', value: 'true', permission_id: permission[:id]] != nil
    end

    def _Role
      @_Role ||= DB.conn[roles_table]
    end

    def _Permission
      @_Permission ||= DB.conn[permissions_table]
    end

    def _PermissionParam
      @_PermissionParam ||= DB.conn[permission_params_table]
    end
  end
end
