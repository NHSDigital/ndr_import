require 'active_model' # Source I18n translations

module NdrImport
  # Raised if a mandatory field is blank.
  class MissingFieldError < StandardError
    attr_reader :field

    def initialize(field)
      @field = field
      message = "#{field} #{I18n.t('errors.messages.blank')}"
      super(message)
    end
  end
end
