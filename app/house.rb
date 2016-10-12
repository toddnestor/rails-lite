class House < SQLObject
  has_many :humans
  
  self.finalize!
end
