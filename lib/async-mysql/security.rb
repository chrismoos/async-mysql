module AsyncMysql
  module Security
    def self.scramble_password(password, scramble)
      return "" if password == ''
      
      stage1 = Digest::SHA1.digest(password)
      stage2 = Digest::SHA1.digest(stage1)
      stage3 = Digest::SHA1.digest(scramble + stage2)
      token = ""
      
      stage3.length.times do |x|
        token << (stage3[x] ^ stage1[x])
      end
      
      return token
    end
  end
end