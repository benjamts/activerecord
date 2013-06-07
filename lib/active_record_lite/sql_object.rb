require_relative './associatable'
require_relative './db_connection'
require_relative './mass_object'
require_relative './searchable'
require 'active_support/inflector'

class SQLObject < MassObject
  extend Searchable
  extend Associatable

  def self.set_table_name(table_name)
    @table_name = table_name.underscore
  end

  def self.table_name
    @table_name
  end

  def self.all
    query = <<-SQL
    SELECT *
    FROM #{self.table_name}
    SQL


    DBConnection.execute(query).map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    query = <<-SQL
    SELECT *
    FROM #{self.table_name}
    WHERE id = ?
    SQL

    self.new(DBConnection.execute(query, id).first)
  end

  def create
    values = attribute_values
    marks = (["?"] * values.length).join(", ")
    query = <<-SQL
  INSERT INTO #{self.class.table_name} (#{self.class.attributes.join(", ")})
    VALUES (#{marks})
    SQL

    DBConnection.execute(query, values)
    self.id = DBConnection.last_insert_row_id
  end

  def update
    values = attribute_values
    marks = (["?"] * values.length).join(", ")
    set_row = self.class.attributes.map{ |attr_name| "#{attr_name} = ?" }.join(", ")
    query = <<-SQL
    UPDATE #{self.class.table_name}
    SET #{set_row}
    WHERE id = ?
    SQL

    DBConnection.execute(query, attribute_values, self.id)
  end

  def save
    self.id.nil? ? create : update
  end

  def attribute_values
    values = self.class.attributes.map do |attr|
      send(attr)
    end
  end
end
