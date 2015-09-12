require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    where_line = params.keys.map {|key| "#{key} = ?"}.join(' AND ')
    vals = params.values
    attr_array =  DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{table_name}
      WHERE
        #{where_line}
      SQL

    attr_array.map {|attrs| self.new(attrs)}
  end


end

class SQLObject
  extend Searchable
end
