module AsyncMysql
  class Row
    attr_accessor :columns, :data, :attributes
    
    def initialize
      self.data = []
      self.attributes = {}
    end
    
    def finalize
      @columns.length.times do |x|
        self.attributes[@columns[x].org_name] = @data[x]
      end 
    end
    
    def to_s
      "#<AsyncMysql::Row attributes=#{attributes}>"
    end
    
    def method_missing(symbol, *args)
      if self.attributes.has_key? symbol.to_s
        return self.attributes[symbol.to_s]
      else
        super(symbol, args)
      end
    end
  end
end