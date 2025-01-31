module Plaidable
  extend ActiveSupport::Concern

  class_methods do
    def plaid_us_provider
      Provider::Plaid.new(Rails.application.config.plaid, :us) if Rails.application.config.plaid
    end

    def plaid_eu_provider
      Provider::Plaid.new(Rails.application.config.plaid_eu, :eu) if Rails.application.config.plaid_eu
    end

    def plaid_provider_for_region(region)
      region.to_sym == :eu ? plaid_eu_provider : plaid_us_provider
    end
  end

  private
    def eu?
      raise "eu? is not implemented for #{self.class.name}"
    end

    def plaid_provider
      eu? ? self.class.plaid_eu_provider : self.class.plaid_us_provider
    end
end
