require_relative '03_associatable'

# Phase IV
module Associatable
  # Remember to go back to 04_associatable to write ::assoc_options

  # def has_one_through(name, through_name, source_name)
  #   through_options = self.class.assoc_options[through_name]
  #   method_name = "#{through_options.class_name}.underscore".to_sym
  #
  #   define_method(method_name) do
  #     source_options = through_options.model_class.assoc_options[source_name]
  #
  #     self.send("#{through_options.class_name}.underscore")
  #
  #     through_model = through_options.class_name
  #
  #     through_model.send()
  #   end
  #
  #   end
  # end

  def has_one_through(name, through_name, source_name)
    through_options = assoc_options[through_name]

    define_method("#{name}".underscore.to_sym) do
      source_options = through_options.model_class.assoc_options[source_name]
      attrs = DBConnection.execute(<<-SQL).first
        SELECT
          #{source_options.table_name}.*
        FROM
          #{through_options.table_name}
        JOIN
          #{source_options.table_name}
          ON #{source_options.foreign_key} = #{through_options.table_name}.id
        WHERE
          #{through_options.table_name}.id
            = #{attributes[through_options.foreign_key]}
      SQL

      source_options.class_name.constantize.new(attrs)
    end

  end
end
