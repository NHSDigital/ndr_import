require 'ndr_import/version'
require 'ndr_import/csv_library'
require 'ndr_import/mapping_error'
require 'ndr_import/missing_field_error'
require 'ndr_import/mapper'
require 'ndr_import/non_tabular_file_helper'
require 'ndr_import/table'
require 'ndr_import/non_tabular/table'
require 'ndr_import/fixed_width/table'
require 'ndr_import/xml/table'

module NdrImport
  def self.root
    ::File.expand_path('../..', __FILE__)
  end
end
