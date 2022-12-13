# This file allows us to choose the CSV library we want to use.

require 'csv'
require 'active_support/deprecation'

# Using relevant core CSV library.
class CSVLibrary < CSV; end

class << CSVLibrary
  # Is the library we're using FasterCSV?
  def fastercsv?
    deprecate('if you desparately want fastercsv, please use it explicitly')
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
    deprecate('CSV#foreach exists, with an optional `mode` argument')
    return to_enum(__method__, path, **options) unless block
    open(path, options.delete(:mode) || 'r', **options) do |csv|
      csv.each(&block)
    end
  end

  def write_csv_to_string(data)
    deprecate('write_csv_to_string -> generate')
    self.generate do |csv|
      data.each { |line| csv << line }
    end
  end

  def write_csv_to_file(data, filepath, mode = 'w')
    deprecate('write_csv_to_file -> open')
    self.open(filepath, mode) do |csv|
      data.each { |line| csv << line }
    end
  end

  def read_csv_from_file(filepath)
    deprecate('read_csv_from_file -> read')
    self.read(filepath)
  end

  private

  def deprecate(additional_message = nil)
    ActiveSupport::Deprecation.warn(<<~MESSAGE)
      CSVLibrary is deprecated, and will be removed in a future version of ndr_import.
      Please use standard functionality provided by Ruby's CSV library (#{additional_message}).
    MESSAGE
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
