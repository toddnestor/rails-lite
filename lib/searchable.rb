require_relative 'relation'

module Searchable
  def where(params)
    relation = Relation.new(self)
    relation.where(params)
  end
end
