module Grut
  module Asset
    def self.stringify_hash(hash)
      hash.reduce({}) do |res, (key, val)|
        res[key.to_s] = val.to_s
        res
      end
    end

    def self.sanitize_contract_hash(hash)
      hash.reduce({}) do |res, (key, val)|
        res[:"key_#{key}"] = key
        res[:"val_#{val}"] = val
        res
      end
    end

    def self.contract_sql_condition(hash)
      hash.map do |key, value|
        "key = :key_#{key} and value = :val_#{value}"
      end.join(' and ')
    end
  end
end
