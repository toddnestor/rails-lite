class Cat < SQLObject
  belongs_to :human,
    foreign_key: :owner_id

  self.finalize!
end
