module NdrImport
  module Xml
    # This class applies a do_not_capture mask to those mappings that do not relate to each klass.
    # Overriding the NdrImport::Table method to avoid memoizing. This by design, column mappings
    # can change if new mappings are added on the fly where repeating sections are present
    class MaskedMappings
      attr_accessor :klass, :augmented_columns

      def initialize(klass, augmented_columns)
        @klass             = klass
        @augmented_columns = augmented_columns
      end

      def call
        return { klass => augmented_columns } if klass.present?

        masked_mappings = column_level_klass_masked_mappings

        augmented_masked_mappings = masked_mappings
        # Remove any masked klasses where additional columns mappings
        # have been added for repeated sections
        # e.g. SomeTestKLass column mappings are not needed if SomeTestKlass#1
        # have been added
        masked_mappings.each_key do |masked_key|
          if masked_mappings.keys.any? { |key| key =~ /\A#{masked_key}#\d+/ }
            augmented_masked_mappings.delete(masked_key)
          end
        end

        augmented_masked_mappings
      end

      private

      # This method duplicates the mappings and applies a do_not_capture mask to those that do not
      # relate to this klass, returning the masked mappings
      def mask_mappings_by_klass(klass)
        augmented_columns.deep_dup.map do |mapping|
          Array(mapping['klass']).flatten.include?(klass) ? mapping : { 'do_not_capture' => true }
        end
      end

      def column_level_klass_masked_mappings
        ensure_mappings_define_klass

        # Loop through each klass
        masked_mappings = {}
        augmented_columns.pluck('klass').flatten.compact.uniq.each do |klass|
          # Do not capture fields that relate to other klasses
          masked_mappings[klass] = mask_mappings_by_klass(klass)
        end
        masked_mappings
      end

      # This method ensures that every column mapping defines a klass (unless it is a column that
      # we do not capture). It is only used where a table level klass is not defined.
      def ensure_mappings_define_klass
        klassless_mappings = augmented_columns.
                             select { |mapping| mapping.nil? || mapping['klass'].nil? }.
                             reject { |mapping| mapping['do_not_capture'] }.
                             map { |mapping| mapping['column'] || mapping['standard_mapping'] }

        return if klassless_mappings.empty?

        # All column mappings for the single item file require a klass definition.
        raise "Missing klass for column(s): #{klassless_mappings.to_sentence}"
      end
    end
  end
end
