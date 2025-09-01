module NdrImport
  module Xml
    # This class applies a do_not_capture mask to those mappings that do not relate to each klass.
    # Overriding the NdrImport::Table method to avoid memoizing. This by design, column mappings
    # can change if new mappings are added on the fly where repeating sections are present
    class MaskedMappings
      attr_reader :klass, :augmented_columns

      def initialize(klass, augmented_columns)
        @klass             = klass
        @augmented_columns = augmented_columns
      end

      def call
        return { klass => augmented_columns } if klass.present?

        masked_mappings = build_column_level_klass_masked_mappings
        remove_superseded_base_klasses(masked_mappings)
      end

      private

      def build_column_level_klass_masked_mappings
        validate_all_mappings_have_klass

        all_klasses.each_with_object({}) do |current_klass, masked_mappings|
          masked_mappings[current_klass] = mask_mappings_for_klass(current_klass)
        end
      end

      def all_klasses
        @all_klasses ||= augmented_columns.
                         pluck('klass').
                         flatten.
                         compact.
                         uniq
      end

      # Remove base klasses that have numbered variants (e.g., remove 'SomeTestKlass'
      # when 'SomeTestKlass#1' exists), unless explicitly marked to keep
      def remove_superseded_base_klasses(masked_mappings)
        masked_mappings.dup.tap do |result|
          masked_mappings.each do |klass, columns|
            next if should_keep_base_klass?(columns)

            result.delete(klass) if numbered_variants?(klass, masked_mappings.keys)
          end
        end
      end

      def should_keep_base_klass?(columns)
        columns.any? { |column| column.dig('xml_cell', 'keep_klass') }
      end

      def numbered_variants?(klass, all_klass_keys)
        numbered_pattern = /\A#{Regexp.escape(klass)}#\d+\z/
        all_klass_keys.any? { |key| key.match?(numbered_pattern) }
      end

      # Creates masked mappings for a specific klass by duplicating all mappings
      # and marking non-matching ones with do_not_capture
      def mask_mappings_for_klass(target_klass)
        augmented_columns.deep_dup.map do |mapping|
          mapping_applies_to_klass?(mapping, target_klass) ? mapping : { 'do_not_capture' => true }
        end
      end

      def mapping_applies_to_klass?(mapping, target_klass)
        Array(mapping['klass']).flatten.include?(target_klass)
      end

      # Validates that all mappings define a klass (except those marked as do_not_capture)
      # Only used when table-level klass is not defined
      def validate_all_mappings_have_klass
        klassless_mappings = find_klassless_mappings
        return if klassless_mappings.empty?

        raise "Missing klass for column(s): #{klassless_mappings.to_sentence}"
      end

      def find_klassless_mappings
        augmented_columns.
          select { |mapping| klassless_mapping?(mapping) }.
          reject { |mapping| mapping['do_not_capture'] }.
          filter_map { |mapping| mapping['column'] || mapping['standard_mapping'] }
      end

      def klassless_mapping?(mapping)
        mapping.nil? || mapping['klass'].nil?
      end
    end
  end
end
