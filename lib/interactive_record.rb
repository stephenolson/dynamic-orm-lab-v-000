require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    results = []
    table_info.each {|chunk| results << chunk["name"] }
    results.compact
  end

  def initialize(options={})
    options.each { |key, value| self.send("#{key}=", value) }
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    self.class.column_names.delete_if{|column| column == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def question_marks_for_insert
    (values_for_insert.length).times.collect{"?"}.join(",")
  end

  def save
    self.id ? update : insert
  end

  def update
    sql = <<-SQL
      UPDATE ?
      SET ? = ?
      WHERE id = ?;
    SQL
    DB[:conn].execute(sql, self.table_name_for_insert, self.col_names_for_insert, self.values_for_insert, self.id)

  end

  def insert
    sql = <<-SQL
      INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert})
      VALUES (#{self.values_for_insert});
    SQL
      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
  end

def self.find_by_name(name)
  sql = <<-SQL
    SELECT * FROM #{self.table_name}
    WHERE name = ?;
  SQL
  DB[:conn].execute(sql, name)
end

def self.find_by(attribute)
  sql = <<-SQL
    SELECT * FROM #{self.table_name}
    WHERE #{attribute.keys.first.to_s} = '#{attribute.values.first}';
  SQL
  DB[:conn].execute(sql)
end

end