# This file allows us to choose the CSV library we want to use.

require 'csv'
# Using relevant core CSV library.
CSVLibrary = CSV

class << CSVLibrary
  # Is the library we're using FasterCSV?
  def fastercsv?
    not self.const_defined?(:Reader)
  end

  def write_csv_to_string(data)
    self.generate do |csv|
      data.each {|line| csv << line }
    end
  end

  def write_csv_to_file(data, filepath, mode="w")
    self.open(filepath, mode) do |csv|
      data.each {|line| csv << line }
    end
  end

  def read_csv_from_file(filepath)
    self.read(filepath)
  end
end

# Forward port CSV::Cell, as it is sometimes
# serialised in YAML. :-(
class CSV::Cell < String
  def initialize(data = "", is_null = false)
    super(is_null ? "" : data)
  end

  def data
    to_s
  end
end
