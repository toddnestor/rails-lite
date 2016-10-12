class Relation
  attr_accessor :selects, :from, :wheres, :groups, :joins

  include Enumerable

  def initialize(calling_object)
    @caller = calling_object
    @selects = []
    @wheres = []
    @groups = []
    @joins = []
    @where_values = []
  end

  def where(params)
    params.each do |key, val|
      @wheres << {col: key, value: '?'}
      @where_values << val
    end

    self
  end

  def each(&prc)
    self.load.each do |el|
      prc.call(el)
    end
  end

  def load
    @selects << '*' if @selects.empty?
    sql = @caller.build_select(@selects) + @caller.build_from(@joins) + @caller.build_where(@wheres)
    @caller.get_objects(sql, @where_values)
  end

  def objects
    @objects ||= load
  end

  def length
    objects.length
  end

  def ==(something)
    objects == something
  end

  def [](id)
    objects[id]
  end
end
