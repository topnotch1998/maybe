class TimeSeries::Trend
  include ActiveModel::Validations

  attr_reader :current, :previous

  delegate :favorable_direction, to: :series

  validate :values_must_be_of_same_type, :values_must_be_of_known_type

  def initialize(current:, previous:, series: nil)
    @current = current
    @previous = previous
    @series = series

    validate!
  end

  def direction
    if previous.nil? || current == previous
      "flat"
    elsif current && current > previous
      "up"
    else
      "down"
    end.inquiry
  end

  def value
    if previous.nil?
      current.is_a?(Money) ? Money.new(0) : 0
    else
      current - previous
    end
  end

  def percent
    if previous.nil?
      0.0
    elsif previous.zero?
      Float::INFINITY
    else
      change = (current_amount - previous_amount)
      base = previous_amount.to_f

      (change / base * 100).round(1).to_f
    end
  end

  def as_json
    {
      favorable_direction: favorable_direction,
      direction: direction,
      value: value,
      percent: percent
    }.as_json
  end

  private
    attr_reader :series

    def values_must_be_of_same_type
      unless current.class == previous.class || [ previous, current ].any?(&:nil?)
        errors.add :current, "must be of the same type as previous"
        errors.add :previous, "must be of the same type as current"
      end
    end

    def values_must_be_of_known_type
      unless current.is_a?(Money) || current.is_a?(Numeric) || current.nil?
        errors.add :current, "must be of type Money, Numeric, or nil"
      end

      unless previous.is_a?(Money) || previous.is_a?(Numeric) || previous.nil?
        errors.add :previous, "must be of type Money, Numeric, or nil"
      end
    end

    def current_amount
      extract_numeric current
    end

    def previous_amount
      extract_numeric previous
    end

    def extract_numeric(obj)
      if obj.is_a? Money
        obj.amount
      else
        obj
      end
    end
end
