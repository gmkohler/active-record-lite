require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    "#{@class_name}".constantize
  end

  def table_name
    "#{@class_name}".underscore + "s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || ("#{name}".underscore + "_id").to_sym
    @primary_key = options[:primary_key] || :id

    @class_name = options[:class_name] || "#{name}".camelcase
  end
end

class HasManyOptions < AssocOptions
  def initialize(foreign_name, self_class_name, options = {})
    self_class_name ||= self.class.name
    @foreign_key = options[:foreign_key] || ("#{self_class_name}".underscore + "_id").to_sym
    @primary_key = options[:primary_key] || :id

    @class_name = options[:class_name] || "#{foreign_name}".singularize.camelcase
  end

end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    assoc_options[name] = options
    method_name = "#{options.class_name.underscore}".to_sym

    define_method(method_name) do
      foreign_key = options.foreign_key
      primary_key = options.primary_key
      options.model_class.where(:id => attributes[foreign_key]).first
    end

  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, self.name, options)
    method_name = options.table_name.to_sym

    define_method(method_name) do
      p foreign_key = options.foreign_key
      p primary_key = options.primary_key
      options.model_class.where(foreign_key => attributes[primary_key])
    end

  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
