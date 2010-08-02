module AsyncMysql
  class Column
    attr_accessor :catalog, :db, :table, :org_table, :name, :org_name, :charsetnr, :length, :type, :flags, :decimal, :default
    
    def type_name
      raise Exception.new("Unknown field type: #{self.type}") if not AsyncMysql::Constants::FIELD_TYPES.has_key? self.type
      return AsyncMysql::Constants::FIELD_TYPES[self.type]
    end
    
    def to_s
      "#<AsyncMysqlColumn column=#{self.org_name}, type=#{type_name}>"
    end
  end
end