module Grut
  class Guardian
    include Concerns::DBTables

    def initialize(user, role)
      @user = user
      @role = role.to_s
      @statement = Grut::Statement.new(@user)
    end

    def permit(permission, params = {})
      params = Asset.stringify_hash(params)
      permission = permission.to_s

      return false if allowed?(permission, params)
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

      allowed?(permission, params)
    end

    private

    def allowed?(permission, params)
      params = Asset.stringify_hash(params)

      contracts = @statement.all(role: @role, permission: permission)

      is_everything = @statement.all(role: @role, permission: 'manage').find { |c| c.contract_key == 'all' && c.contract_value == 'true' } != nil
      is_all_entities = contracts.find { |c| c.contract_key == 'all' && c.contract_value == 'true' } != nil
      is_excempt = contracts.find { |c| c.contract_key == 'except' && c.contract_value == params } != nil
      is_exclusive = contracts.find { |c| c.contract_key == 'exclusive' && c.contract_value == params } != nil

      is_exclusive || ((is_everything || is_all_entities) && !is_excempt)
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
          return if allowed?(permission_name, params)
          _PermissionParam.insert(permission_id: permission_id, key: 'exclusive', value: YAML.dump(params))
        end
      end
    end

    def forbit_role_with_params(permission_name, params)
      is_all = params == {'all' => 'true'}

      role_id = entity_id(_Role[user_id: @user.id])
      return unless role_id

      permission_id = entity_id(_Permission[role_id: role_id, name: permission_name])
      return unless permission_id

      DB.conn.transaction do
        if is_all
          _PermissionParam.where(permission_id: permission_id).delete
        else
          permission_param_ids = if is_all
            []
          else
            _PermissionParam.where(permission_id: permission_id, key: 'exclusive').map do |pp|
              YAML.load(pp[:value]) == params ? pp[:id] : nil
            end.compact
          end
          params.map do |key, val|
            entity_id(_PermissionParam[permission_id: permission_id, key: key, value: val])
          end.compact

          _PermissionParam.where(id: permission_param_ids).delete

          everything_permission_id = entity_id(_Permission[role_id: role_id, name: 'manage'])

          if !params.empty? && !is_all && (_PermissionParam[permission_id: permission_id, key: 'all', value: 'true'] || _PermissionParam[permission_id: everything_permission_id, key: 'all', value: 'true'])
            _PermissionParam.insert(permission_id: permission_id, key: 'except', value: YAML::dump(params))
          end
        end
        _Permission.where(id: permission_id).delete if _PermissionParam.count(permission_id: permission_id) == 0
        _Role.where(id: role_id).delete if _Permission.count(role_id: role_id) == 0
      end
    end

    def find_or_create(entity, params)
      entity_id(entity[params]) || entity.insert(params)
    end

    def role_manages_all?(role_id)
      permission = _Permission[name: 'manage', role_id: role_id]
      return false unless permission
      _PermissionParam[key: 'all', value: 'true', permission_id: permission[:id]] != nil
    end

    def entity_id(entity)
      (entity || {})[:id]
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
