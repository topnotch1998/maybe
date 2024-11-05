require "test_helper"

module AccountableResourceInterfaceTest
  extend ActiveSupport::Testing::Declarative

  test "shows new form" do
    get new_polymorphic_url(@account.accountable)
    assert_response :success
  end

  test "shows edit form" do
    get edit_account_url(@account)
    assert_response :success
  end

  test "renders accountable page" do
    get account_url(@account)
    assert_response :success
  end

  test "destroys account" do
    delete account_url(@account)
    assert_redirected_to accounts_path
    assert_equal "#{@account.accountable_name.humanize} account deleted", flash[:notice]
  end

  test "updates basic account balances" do
    assert_no_difference [ "Account.count", "@account.accountable_class.count" ] do
      patch account_url(@account), params: {
        account: {
          institution_id: institutions(:chase).id,
          name: "Updated name",
          balance: 10000,
          currency: "USD"
        }
      }
    end

    assert_redirected_to @account
    assert_equal "#{@account.accountable_name.humanize} account updated", flash[:notice]
  end

  test "creates with basic attributes" do
    assert_difference [ "Account.count", "@account.accountable_class.count" ], 1 do
      post "/#{@account.accountable_name.pluralize}", params: {
        account: {
          accountable_type: @account.accountable_class,
          institution_id: institutions(:chase).id,
          name: "New accountable",
          balance: 10000,
          currency: "USD",
          subtype: "checking"
        }
      }
    end

    assert_redirected_to Account.order(:created_at).last
    assert_equal "#{@account.accountable_name.humanize} account created", flash[:notice]
  end

  test "updates account balance by creating new valuation" do
    assert_difference [ "Account::Entry.count", "Account::Valuation.count" ], 1 do
      patch account_url(@account), params: {
        account: {
          balance: 10000
        }
      }
    end

    assert_redirected_to @account
    assert_enqueued_with job: AccountSyncJob
    assert_equal "#{@account.accountable_name.humanize} account updated", flash[:notice]
  end

  test "updates account balance by editing existing valuation for today" do
    @account.entries.create! date: Date.current, amount: 6000, currency: "USD", entryable: Account::Valuation.new

    assert_no_difference [ "Account::Entry.count", "Account::Valuation.count" ] do
      patch account_url(@account), params: {
        account: {
          balance: 10000
        }
      }
    end

    assert_redirected_to @account
    assert_enqueued_with job: AccountSyncJob
    assert_equal "#{@account.accountable_name.humanize} account updated", flash[:notice]
  end
end
