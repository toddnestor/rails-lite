require_relative 'db_connection'
require_relative 'associatable'
require_relative 'searchable'

require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  extend Searchable
  extend Associatable

  def self.columns
    @columns ||= self.get_columns
  end

  def self.get_columns
    data = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT 1
    SQL

    data.first.map {|col| col.to_sym}
  end

  def self.finalize!
    self.columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |value|
        attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.name.tableize
  end

  def self.build_select(attrs = nil)
    attrs ||= ['*']
    attrs = [attrs] unless attrs.is_a?(Array)

    sql = <<-SQL
      SELECT
        #{attrs.join(', ')}
    SQL
    sql
  end

  def self.build_joins(joins = [])
    join_strings = []

    joins.each do |join|
      if join[:table] && join[:on]
        join_strings << <<-SQL
          #{join[:type] ? join[:type].upcase : 'JOIN'} #{join[:table]} ON #{join[:on]}
        SQL
      end
    end

    join_strings.join("\n")
  end

  def self.build_from(joins = [], table = self.table_name)
    sql = <<-SQL
      FROM
        #{table}
        #{self.build_joins(joins)}
    SQL

    sql
  end

  def self.build_where_clauses(wheres)
    wheres = [wheres] unless wheres.is_a?(Array)

    where_strings = []

    wheres.each_with_index do |where, i|
      where_string = ""

      where[:type] ||= 'AND '
      where[:comparator] ||= '='

      where_string += i > 0 ? "#{where[:type]}" : ""

      if where.is_a?(Array)
        where_string += self.build_where(where)
      else
        col_parts = where[:col].to_s.split('.')
        next unless columns.include?(where[:col]) || col_parts.length > 1
        where_string += "#{where[:col]} #{where[:comparator]} #{where[:value]}"
      end

      where_strings << where_string
    end

    where_strings.join("\n")
  end

  def build_insert
    <<-SQL
      INSERT INTO
        #{self.class.table_name}
        (#{attributes.keys.join(', ')})
      VALUES
        (#{attributes.keys.map{'?'}.join(', ')})
    SQL
  end

  def build_update
    <<-SQL
      UPDATE
        #{self.class.table_name}
      SET
        #{build_update_columns.join(', ')}
    SQL
  end

  def build_update_columns
    columns = []

    attributes.keys.each do |key|
      columns << "#{key} = ?" unless key == :id
    end

    columns
  end

  def update_attributes
    values = []

    attributes.each do |key, value|
      values << value unless key == :id
    end

    values
  end

  def self.build_where(wheres)
    "WHERE #{self.build_where_clauses(wheres)}"
  end

  def self.all
    sql = self.build_select + self.build_from
    self.parse_all(DBConnection.execute(sql))
  end

  def self.execute(*args)
    DBConnection.execute(*args)
  end

  def self.get_last_id
    DBConnection.last_insert_row_id
  end

  def self.get_objects(*args)
    self.parse_all(self.execute(*args))
  end

  def self.parse_all(results)
    results.map {|el| self.new(el)}
  end

  def self.find(id)
    sql = self.build_select + self.build_from + self.build_where(col: :id, value: id)
    self.get_objects(sql).first
  end

  def initialize(params = {})
    params.each do |key, val|
      name = key.to_sym
      raise "unknown attribute '#{name}'" unless self.class.columns.include?(name)
      self.send("#{name}=", val)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    SQLObject.execute(build_insert, *attribute_values)
    self.id = SQLObject.get_last_id
  end

  def update
    values = update_attributes + [self.id]
    sql = build_update + self.class.build_where(col: :id, value: '?')

    SQLObject.execute(sql, values)
  end

  def save
    if self.id
      update
    else
      insert
    end
  end
end
