# This file allows us to choose the CSV library we want to use.

# 1.8.x switch: use fastercsv?
USE_FASTER_CSV = ENV['USE_FASTER_CSV'] || false

require 'csv'
CSVLibrary = if RUBY_VERSION =~ /^1.8/ && USE_FASTER_CSV
  # Explicitly using fastercsv on 1.8.x.
  require 'fastercsv'
  FasterCSV
else
  # Using relevant core CSV library.
  CSV
end

class << CSVLibrary
  # Is the library we're using FasterCSV?
  def fastercsv?
    not self.const_defined?(:Reader)
  end

  def write_csv_to_string(data)
    if fastercsv?
      self.generate do |csv|
        data.each {|line| csv << line }
      end
    else
      string_io = StringIO.new
      self::Writer.generate(string_io, ',') do |csv|
        data.each {|line| csv << line }
      end
      string_io.rewind
      string_io.read
    end
  end

  def write_csv_to_file(data, filepath, mode="w")
    if fastercsv?
      self.open(filepath, mode) do |csv|
        data.each {|line| csv << line }
      end
    else
      File.open(filepath, mode) do |file|
        self::Writer.generate(file) do |csv|
          data.each {|line| csv << line }
        end
      end
    end
  end

  def read_csv_from_file(filepath)
    if fastercsv?
      self.read(filepath)
    else
      self.open(filepath, "r")
    end
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
end if CSVLibrary.fastercsv?
