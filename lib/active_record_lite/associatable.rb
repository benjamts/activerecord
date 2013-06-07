require 'active_support/core_ext/object/try'
require 'active_support/inflector'
require_relative './db_connection.rb'

class AssocParams
  def other_class
  end

  def other_table
  end
end

class BelongsToAssocParams < AssocParams
  attr_accessor :other_class, :primary_key, :foreign_key
  def initialize(name, params)
    @other_class = params[:class_name] || name.to_s.camelize
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name}_id".to_sym
  end

  def type
  end
end

class HasManyAssocParams < AssocParams
  attr_accessor :other_class, :primary_key, :foreign_key
  def initialize(name, params)
    @other_class = params[:class_name] || name.to_s.singularize.camelize
    @primary_key = params[:primary_key] || "id"
    @foreign_key = params[:foreign_key] || "#{name.underscore}_id".to_sym
  end

  def type
  end
end

module Associatable
  def assoc_params
    @assoc_params ||= {}
  end

  def belongs_to(name, params = {})
    assoc_params[name] = BelongsToAssocParams.new(name, params)
    aps = assoc_params[name]
    define_method(name) do
      aps.other_class.constantize.where({aps.primary_key => self.send(aps.foreign_key)})
    end
  end

  def has_many(name, params = {})
    define_method(name) do
      aps = HasManyAssocParams.new(name, params)
      aps.other_class.constantize.where({aps.foreign_key => self.send(aps.primary_key)})
    end
  end

  def has_one_through(name, assoc1, assoc2)
    define_method(name) do
      human = self.class.assoc_params[assoc1]
      house = human.other_class.constantize.assoc_params[name]

      human_table = human.other_class.constantize.table_name
      house_table = house.other_class.constantize.table_name

      query = <<-SQL
      SELECT DISTINCT #{house_table}.*
      FROM #{house_table}
      JOIN #{human_table}
      ON #{house.foreign_key} = #{house_table}.#{house.primary_key}
      WHERE #{house_table}.#{house.primary_key} = #{house.foreign_key}
      SQL

      DBConnection.execute(query)
    end
  end
end



