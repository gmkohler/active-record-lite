require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject

  def self.columns
    cols = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
      SQL

    cols.first.map {|str| str.to_sym}
  end

  def self.finalize!

    define_method(:attributes) do
      @attributes ||= {}
    end

    self.columns.each do |column|
      define_method(column) do
        attributes[column]
      end

      define_method("#{column}=") do |val|
        attributes[column] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name.nil?
      @table_name = self.name.underscore.pluralize
    end
    @table_name
  end

  def self.all
    attr_array = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
    SQL

    parse_all(attr_array)
  end

  def self.parse_all(results)
    results.map {|attrs| self.new(attrs)}
  end

  def self.find(id)
    attrs = DBConnection.execute(<<-SQL)
      SELECT
        #{table_name}.*
      FROM
        #{table_name}
      WHERE
        id = #{id}
    SQL

    parse_all(attrs).first
  end

  def initialize(params = {})
    params.each do |key, val|
      key = key.to_sym
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key)
      attributes[key] = val
    end
  end

  def attributes
    # ...
  end

  def attribute_values(cols = self.class.columns)
    cols.map {|col_name| attributes[col_name]}
  end

  def insert
    cols = self.class.columns

    col_names = "(" + cols.join(', ') + ")"
    vals = attribute_values(cols)

    question_marks = "(" + (["?"] * (vals.size)).join(', ') + ")"
    DBConnection.execute(<<-SQL, *vals)
      INSERT INTO
        #{self.class.table_name} #{col_names}
      VALUES
        #{question_marks}
    SQL

    attributes[:id] = DBConnection.last_insert_row_id

    attributes.values
  end


  def update
    cols = self.class.columns

    set_line = cols.map {|col| "#{col} = ?"}.join(', ')
    vals = attribute_values(cols)


    DBConnection.execute(<<-SQL, *vals, attributes[:id])
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = ?
    SQL
  end

  def save
    attributes[:id].nil? ? insert : update
  end
end

class UnknownAttrError < StandardError
end
