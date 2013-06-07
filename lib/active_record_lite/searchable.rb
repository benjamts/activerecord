require_relative './db_connection'

module Searchable
  def where(params)
    where_clause = params.keys.map{|key| "#{key} = ?"}.join(" AND ")
    values = params.values
    query = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE #{where_clause}
    SQL
    DBConnection.execute(query, values)
  end
end