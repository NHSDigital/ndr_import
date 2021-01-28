# This file allows us to choose the CSV library we want to use.

require 'csv'
# Using relevant core CSV library.
CSVLibrary = CSV

class << CSVLibrary
  # Is the library we're using FasterCSV?
  def fastercsv?
    not self.const_defined?(:Reader)
  end

  # Ensure that we can pass "mode" straight through the underlying IO object
  #
  # Note: this could likely be refactored now, as upstream support for something
  #       very similar was added:
  #
  #       https://github.com/ruby/csv/commit/b4edaf2cf1aa36f5c6264c07514b66739b87ceee
  #
  def foreach(path, **options, &block)
    return to_enum(__method__, path, **options) unless block
    open(path, options.delete(:mode) || 'r', **options) do |csv|
      csv.each(&block)
    end
  end

  def write_csv_to_string(data)
    self.generate do |csv|
      data.each { |line| csv << line }
    end
  end

  def write_csv_to_file(data, filepath, mode = 'w')
    self.open(filepath, mode) do |csv|
      data.each { |line| csv << line }
    end
  end

  def read_csv_from_file(filepath)
    self.read(filepath)
  end
end

# Forward port CSV::Cell, as it is sometimes
# serialised in YAML. :-(
class CSV::Cell < String
  def initialize(data = '', is_null = false)
    super(is_null ? '' : data)
  end

  def data
    to_s
  end
end
