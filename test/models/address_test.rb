require "test_helper"

class AddressTest < ActiveSupport::TestCase
  test "can print a formatted address" do
    address = Address.new(
      line1: "123 Main St",
      locality: "San Francisco",
      region: "CA",
      country: "US",
      postal_code: "94101"
    )

    assert_equal "123 Main St\n\nSan Francisco, CA 94101\nUS", address.to_s
  end
end
