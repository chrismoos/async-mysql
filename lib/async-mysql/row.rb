module AsyncMysql
  class Row
    attr_accessor :columns, :data
    
    def initialize
      self.data = []
    end
    
    def attributes
      attrs = {}
      @columns.length.times do |x|
        attrs[@columns[x].org_name] = @data[x]
      end
      return attrs
    end
    
    def to_s
      "#<AsyncMysql::Row attributes=#{attributes}>"
    end
  end
end