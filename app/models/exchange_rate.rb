class ExchangeRate < ApplicationRecord
  include Provided

  validates :base_currency, :converted_currency, presence: true

  class << self
    def find_rate(from:, to:, date:)
      find_by \
        base_currency: Money::Currency.new(from).iso_code,
        converted_currency: Money::Currency.new(to).iso_code,
        date: date
    end

    def find_rate_or_fetch(from:, to:, date:)
      find_rate(from:, to:, date:) || fetch_rate_from_provider(from:, to:, date:)&.tap(&:save!)
    end

    def get_rates(from, to, dates)
      where(base_currency: from, converted_currency: to, date: dates).order(:date)
    end

    def convert(value:, from:, to:, date:)
      rate = ExchangeRate.find_by(base_currency: from, converted_currency: to, date:)
      raise "Conversion from: #{from} to: #{to} on: #{date} not found" unless rate

      value * rate.rate
    end
  end
end
