require 'ndr_support/safe_file'

module NdrImport
  module Helpers
    module File
      # This mixin adds excel spreadsheet functionality to unified importers.
      # It provides a file reader method and methods to cast raw values
      # appropriately. These methods can be overridden or aliased as required.
      #
      module Excel
        require 'roo'
        require 'roo-xls'
        require 'ole/storage'

        protected

        def cast_excel_value(raw_value)
          return raw_value if raw_value.nil?

          if raw_value.is_a?(Date) || raw_value.is_a?(DateTime) || raw_value.is_a?(Time)
            cast_excel_datetime_as_date(raw_value)
          elsif raw_value.is_a?(Float)
            if raw_value.to_f == raw_value.to_i
              # Whole number
              return raw_value.to_i.to_s
            else
              return raw_value.to_f.to_s
            end
          else
            return raw_value.to_s.strip
          end
        end

        def cast_excel_datetime_as_date(raw_value)
          raw_value.to_s(:db)
        end

        # Iterate through the file table by table, yielding each one in turn.
        def excel_tables(path)
          return enum_for(:excel_tables, path) unless block_given?

          workbook = load_workbook(path)
          workbook.each_with_pagename do |tablename, sheet|
            yield tablename, excel_rows(workbook, sheet)
          end
        end

        private

        def read_excel_file(path, selected_sheet = nil)
          # SECURE: TVB Mon Aug 13 15:30:32 BST 2012 SafeFile.safepath_to_string makes sure that
          # the path is SafePath.

          # Load the workbook
          workbook = load_workbook(path)

          # Choose selected worksheet (if provided and exist) or the first worksheet
          workbook.default_sheet =
            if selected_sheet.nil? || !workbook.sheets.include?(selected_sheet.to_s)
              workbook.sheets.first
            else
              selected_sheet.to_s
            end

          # Read the cells from working worksheet into a nested array
          excel_rows(workbook, workbook).to_a
        end

        # Iterate through the sheet line by line, yielding each one in turn.
        def excel_rows(workbook, sheet, &block)
          return enum_for(:excel_rows, workbook, sheet) unless block

          if workbook.is_a?(Roo::Excelx)
            # FIXME: xlsx_rows(sheet, &block) should produce the same output as xls_rows
            xls_rows(sheet, &block)
          else
            xls_rows(sheet, &block)
          end
        end

        # Iterate through an xls sheet line by line, yielding each one in turn.
        def xls_rows(sheet)
          return enum_for(:xls_rows, sheet) unless block_given?
          return unless sheet.first_row # NULL Sheet (TODO: perhaps XLSX only, use xlsx_rows...)

          sheet.first_row.upto(sheet.last_row) do |row|
            line = []
            sheet.first_column.upto(sheet.last_column) do |col|
              line << cast_excel_value(sheet.cell(row, col))
            end
            yield line
          end
        end

        # Iterate through an xlsx sheet line by line, yielding each one in turn.
        # This method uses streaming https://github.com/roo-rb/roo#excel-xlsx-and-xlsm-support
        def xlsx_rows(sheet)
          return enum_for(:xlsx_rows, sheet) unless block_given?

          sheet.each_row_streaming(:pad_cells => true) do |row|
            yield row.map { |cell| cast_excel_value(cell.value) }
          end
        end

        def get_excel_sheets_name(path)
          workbook = load_workbook(path)
          workbook.sheets
        end

        def load_workbook(path)
          case SafeFile.extname(path).downcase
          when '.xls'
            Roo::Excel.new(SafeFile.safepath_to_string(path))
          when '.xlsx'
            Roo::Excelx.new(SafeFile.safepath_to_string(path))
          else
            fail "Received file path with unexpected extension #{SafeFile.extname(path)}"
          end
        rescue Ole::Storage::FormatError => e
          # TODO: Do we need to remove the new_file after using it?

          # try to load the .xls file as an .xlsx file, useful for sources like USOM
          # roo check file extensions in file_type_check (GenericSpreadsheet),
          # so we create a duplicate file in xlsx extension
          if /(.*)\.xls$/.match(path)
            new_file_name = SafeFile.basename(path).gsub(/(.*)\.xls$/, '\1_amend.xlsx')
            new_file_path = SafeFile.dirname(path).join(new_file_name)
            copy_file(path, new_file_path)

            load_workbook(new_file_path)
          else
            raise e.message
          end
        rescue => e
          raise ["Unable to read the file '#{path}'", e.message].join('; ')
        end

        # Note that this method can produce insecure calls. All callers must protect
        # their arguments.
        # Arguments:
        #   * source - SafeFile
        #   * dest - SafeFile
        #
        def copy_file(source, dest)
          # SECURE: TVB Mon Aug 13 13:53:02 BST 2012 : Secure SafePath will do the security checks
          # before it is converted to string.
          # SafeFile will make sure that the arguments are actually SafePath
          FileUtils.mkdir_p(SafeFile.safepath_to_string(SafeFile.dirname(dest)))
          FileUtils.cp(SafeFile.safepath_to_string(source), SafeFile.safepath_to_string(dest))
        end
      end
    end
  end
end
