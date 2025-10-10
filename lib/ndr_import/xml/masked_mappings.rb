module NdrImport
  module Xml
    # This class applies a do_not_capture mask to those mappings that do not relate to each klass.
    # Overriding the NdrImport::Table method to avoid memoizing. This by design, column mappings
    # can change if new mappings are added on the fly where repeating sections are present
    class MaskedMappings
      DO_NOT_CAPTURE_MAPPING = { 'do_not_capture' => true }.freeze
      KLASS_KEY              = 'klass'.freeze
      COLUMN_KEY             = 'column'.freeze
      STANDARD_MAPPING_KEY   = 'standard_mapping'.freeze
      DO_NOT_CAPTURE_KEY     = 'do_not_capture'.freeze
      XML_CELL_KEY           = 'xml_cell'.freeze
      KEEP_KLASS_KEY         = 'keep_klass'.freeze

      # Pre-compiled regex for numbered variants
      NUMBERED_VARIANT_PATTERN = /#\d+\z/

      attr_reader :klass, :augmented_columns

      def initialize(klass, augmented_columns)
        @klass             = klass
        @augmented_columns = augmented_columns
        @column_count      = augmented_columns.size
        @has_klass         = !klass.nil?

        freeze
      end

      def call
        return { @klass => @augmented_columns } if @has_klass

        masked_mappings = build_masked_mappings
        remove_superseded_base_klasses(masked_mappings)
      end

      private

      def build_masked_mappings
        # Pre-validate and extract all klasses in one pass
        all_klasses_set, klassless_column_names = extract_klasses_and_validate

        raise "Missing klass for column(s): #{klassless_column_names.join(', ')}" unless klassless_column_names.empty?

        all_klasses_array = all_klasses_set.to_a

        # Pre-allocate result hash with exact size
        result = Hash.new(all_klasses_array.size)

        all_klasses_array.each do |current_klass|
          result[current_klass] = mask_mappings_for_klass(current_klass)
        end

        result
      end

      def extract_klasses_and_validate
        klasses_set            = Set.new
        klassless_column_names = []

        @augmented_columns.each do |mapping|
          mapping_klass = mapping[KLASS_KEY]

          if mapping_klass.nil?
            # Only collect klassless mappings that aren't marked as do_not_capture
            klassless_column_names << column_name_from(mapping) unless mapping[DO_NOT_CAPTURE_KEY]
          elsif mapping_klass.is_a?(Array)
            klasses_set.merge(mapping_klass.compact)
          else
            klasses_set.add(mapping_klass)
          end
        end

        [klasses_set, klassless_column_names]
      end

      def column_name_from(mapping)
        mapping[COLUMN_KEY] || mapping[STANDARD_MAPPING_KEY]
      end

      def mask_mappings_for_klass(target_klass)
        # Pre-allocate array with exact size
        result = Array.new(@column_count)

        # Single pass with index tracking
        @augmented_columns.each_with_index do |mapping, index|
          result[index] = if mapping_applies_to_klass?(mapping, target_klass)
                            mapping.deep_dup
                          else
                            DO_NOT_CAPTURE_MAPPING
                          end
        end

        result
      end

      def mapping_applies_to_klass?(mapping, target_klass)
        mapping_klass = mapping[KLASS_KEY]
        return false unless mapping_klass

        # Optimized type checking and inclusion
        case mapping_klass
        when Array
          mapping_klass.include?(target_klass)
        when String
          mapping_klass == target_klass
        else
          false
        end
      end

      def remove_superseded_base_klasses(masked_mappings)
        return masked_mappings if masked_mappings.size <= 1

        # Pre-build numbered variants lookup for O(1) access
        numbered_klasses = build_numbered_klasses_lookup(masked_mappings.keys)
        return masked_mappings if numbered_klasses.empty?

        klasses_to_keep = compute_klasses_to_keep(masked_mappings)

        masked_mappings.select do |klass, _columns|
          klasses_to_keep.include?(klass) || numbered_klasses.exclude?(klass)
        end
      end

      def build_numbered_klasses_lookup(klass_keys)
        numbered_klasses = Set.new

        klass_keys.each do |key|
          next unless key.match?(NUMBERED_VARIANT_PATTERN)

          # Extract base klass name (everything before #)
          base_klass = key.split(NUMBERED_VARIANT_PATTERN, 2).first
          numbered_klasses.add(base_klass)
        end

        numbered_klasses
      end

      def compute_klasses_to_keep(masked_mappings)
        klasses_to_keep = Set.new

        masked_mappings.each do |klass, columns|
          klasses_to_keep.add(klass) if should_keep_base_klass?(columns)
        end

        klasses_to_keep
      end

      def should_keep_base_klass?(columns)
        # Fast iteration with early termination
        columns.each do |column|
          xml_cell = column[XML_CELL_KEY]
          return true if xml_cell && xml_cell[KEEP_KLASS_KEY]
        end

        false
      end
    end
  end
end
