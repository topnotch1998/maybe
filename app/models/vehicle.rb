class Vehicle < ApplicationRecord
  include Accountable

  attribute :mileage_unit, :string, default: "mi"

  def mileage
    Measurement.new(mileage_value, mileage_unit) if mileage_value.present?
  end

  def purchase_price
    first_valuation_amount
  end

  def trend
    TimeSeries::Trend.new(current: account.balance_money, previous: first_valuation_amount)
  end

  def color
    "#F23E94"
  end

  private
    def first_valuation_amount
      account.entries.account_valuations.order(:date).first&.amount_money || account.balance_money
    end
end
