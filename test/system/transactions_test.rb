require "application_system_test_case"

class TransactionsTest < ApplicationSystemTestCase
  setup do
    sign_in @user = users(:family_admin)

    Account::Entry.delete_all # clean slate

    create_transaction("one", 12.days.ago.to_date, 100)
    create_transaction("two", 10.days.ago.to_date, 100)
    create_transaction("three", 9.days.ago.to_date, 100)
    create_transaction("four", 8.days.ago.to_date, 100)
    create_transaction("five", 7.days.ago.to_date, 100)
    create_transaction("six", 7.days.ago.to_date, 100)
    create_transaction("seven", 4.days.ago.to_date, 100)
    create_transaction("eight", 3.days.ago.to_date, 100)
    create_transaction("nine", 1.days.ago.to_date, 100)
    create_transaction("ten", 1.days.ago.to_date, 100)
    create_transaction("eleven", Date.current, 100, category: categories(:food_and_drink), tags: [ tags(:one) ], merchant: merchants(:amazon))

    @transactions = @user.family.entries
                         .account_transactions
                         .reverse_chronological

    @transaction = @transactions.first

    @page_size = 10

    visit transactions_url(per_page: @page_size)
  end

  test "can search for a transaction" do
    assert_selector "h1", text: "Transactions"

    within "form#transactions-search" do
      fill_in "Search transactions by name", with: @transaction.name
    end

    assert_selector "#" + dom_id(@transaction), count: 1

    within "#transaction-search-filters" do
      assert_text @transaction.name
    end
  end

  test "can open filters and apply one or more" do
    find("#transaction-filters-button").click

    within "#transaction-filters-menu" do
      check(@transaction.account.name)
      click_button "Category"
      check(@transaction.account_transaction.category.name)
      click_button "Apply"
    end

    assert_selector "#" + dom_id(@transaction), count: 1

    within "#transaction-search-filters" do
      assert_text @transaction.account.name
      assert_text @transaction.account_transaction.category.name
    end
  end

  test "all filters work and empty state shows if no match" do
    find("#transaction-filters-button").click

    account = @transaction.account
    category = @transaction.account_transaction.category
    merchant = @transaction.account_transaction.merchant

    within "#transaction-filters-menu" do
      click_button "Account"
      check(account.name)

      click_button "Date"
      fill_in "q_start_date", with: 10.days.ago.to_date
      fill_in "q_end_date", with: 1.day.ago.to_date

      click_button "Type"
      check("Income")

      click_button "Amount"
      select "Less than"
      fill_in "q_amount", with: 200

      click_button "Category"
      check(category.name)

      click_button "Merchant"
      check(merchant.name)

      click_button "Apply"
    end

    assert_text "No entries found"

    # Page reload doesn't affect results
    visit current_url

    assert_text "No entries found"

    within "ul#transaction-search-filters" do
      find("li", text: account.name).first("a").click
      find("li", text: "on or after #{10.days.ago.to_date}").first("a").click
      find("li", text: "on or before #{1.day.ago.to_date}").first("a").click
      find("li", text: "Income").first("a").click
      find("li", text: "less than 200").first("a").click
      find("li", text: category.name).first("a").click
      find("li", text: merchant.name).first("a").click
    end

    assert_selector "#" + dom_id(@transaction), count: 1
  end

  test "can select and deselect entire page of transactions" do
    all_transactions_checkbox.check
    assert_selection_count(number_of_transactions_on_page)
    all_transactions_checkbox.uncheck
    assert_selection_count(0)
  end

  test "can select and deselect groups of transactions" do
    date_transactions_checkbox(1.day.ago.to_date).check
    assert_selection_count(2)

    date_transactions_checkbox(1.day.ago.to_date).uncheck
    assert_selection_count(0)
  end

  test "can select and deselect individual transactions" do
    transaction_checkbox(@transactions.first).check
    assert_selection_count(1)
    transaction_checkbox(@transactions.second).check
    assert_selection_count(2)
    transaction_checkbox(@transactions.second).uncheck
    assert_selection_count(1)
  end

  test "outermost group always overrides inner selections" do
    transaction_checkbox(@transactions.first).check
    assert_selection_count(1)

    all_transactions_checkbox.check
    assert_selection_count(number_of_transactions_on_page)

    transaction_checkbox(@transactions.first).uncheck
    assert_selection_count(number_of_transactions_on_page - 1)

    date_transactions_checkbox(1.day.ago.to_date).uncheck
    assert_selection_count(number_of_transactions_on_page - 3)

    all_transactions_checkbox.uncheck
    assert_selection_count(0)
  end


  test "can create deposit transaction for investment account" do
    investment_account = accounts(:investment)
    transfer_date = Date.current
    visit account_path(investment_account)
    click_on "New transaction"
    select "Deposit", from: "Type"
    fill_in "Date", with: transfer_date
    fill_in "account_entry[amount]", with: 175.25
    click_button "Add transaction"
    within "#account_" + investment_account.id do
      click_on "Transactions"
    end
    within "#entry-group-" + transfer_date.to_s do
      assert_text "175.25"
    end
  end

  private

    def create_transaction(name, date, amount, category: nil, merchant: nil, tags: [])
      account = accounts(:depository)

      account.entries.create! \
        name: name,
        date: date,
        amount: amount,
        currency: "USD",
        entryable: Account::Transaction.new(category: category, merchant: merchant, tags: tags)
    end

    def number_of_transactions_on_page
      [ @user.family.entries.without_transfers.count, @page_size ].min
    end

    def all_transactions_checkbox
      find("#selection_entry")
    end

    def date_transactions_checkbox(date)
      find("#selection_entry_#{date}")
    end

    def transaction_checkbox(transaction)
      find("#" + dom_id(transaction, "selection"))
    end

    def assert_selection_count(count)
      if count == 0
        assert_no_selector("#entry-selection-bar")
      else
        within "#entry-selection-bar" do
          assert_text "#{count} transaction#{count == 1 ? "" : "s"} selected"
        end
      end
    end
end
