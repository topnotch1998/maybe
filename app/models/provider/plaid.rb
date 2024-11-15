class Provider::Plaid
  attr_reader :client

  PLAID_COUNTRY_CODES = %w[US GB ES NL FR IE CA DE IT PL DK NO SE EE LT LV PT BE].freeze
  PLAID_LANGUAGES = %w[da nl en et fr de hi it lv lt no pl pt ro es sv vi].freeze
  PLAID_PRODUCTS = %w[transactions investments liabilities].freeze
  MAX_HISTORY_DAYS = Rails.env.development? ? 90 : 730

  class << self
    def process_webhook(webhook_body)
      parsed = JSON.parse(webhook_body)
      type = parsed["webhook_type"]
      code = parsed["webhook_code"]

      item = PlaidItem.find_by(plaid_id: parsed["item_id"])

      case [ type, code ]
      when [ "TRANSACTIONS", "SYNC_UPDATES_AVAILABLE" ]
        item.sync_later
      when [ "INVESTMENTS_TRANSACTIONS", "DEFAULT_UPDATE" ]
        item.sync_later
      when [ "HOLDINGS", "DEFAULT_UPDATE" ]
        item.sync_later
      else
        Rails.logger.warn("Unhandled Plaid webhook type: #{type}:#{code}")
      end
    end

    def validate_webhook!(verification_header, raw_body)
      jwks_loader = ->(options) do
        key_id = options[:kid]

        jwk_response = client.webhook_verification_key_get(
          Plaid::WebhookVerificationKeyGetRequest.new(key_id: key_id)
        )

        jwks = JWT::JWK::Set.new([ jwk_response.key.to_hash ])

        jwks.filter! { |key| key[:use] == "sig" }
        jwks
      end

      payload, _header = JWT.decode(
        verification_header, nil, true,
        {
          algorithms: [ "ES256" ],
          jwks: jwks_loader,
          verify_expiration: false
        }
      )

      issued_at = Time.at(payload["iat"])
      raise JWT::VerificationError, "Webhook is too old" if Time.now - issued_at > 5.minutes

      expected_hash = payload["request_body_sha256"]
      actual_hash = Digest::SHA256.hexdigest(raw_body)
      raise JWT::VerificationError, "Invalid webhook body hash" unless ActiveSupport::SecurityUtils.secure_compare(expected_hash, actual_hash)
    end

    def client
      api_client = Plaid::ApiClient.new(
        Rails.application.config.plaid
      )

      Plaid::PlaidApi.new(api_client)
    end
  end

  def initialize
    @client = self.class.client
  end

  def get_link_token(user_id:, country:, language: "en", webhooks_url:, redirect_url:, accountable_type: nil)
    request = Plaid::LinkTokenCreateRequest.new({
      user: { client_user_id: user_id },
      client_name: "Maybe Finance",
      products: get_products(accountable_type),
      country_codes: [ get_plaid_country_code(country) ],
      language: get_plaid_language(language),
      webhook: webhooks_url,
      redirect_uri: redirect_url,
      transactions: { days_requested: MAX_HISTORY_DAYS }
    })

    client.link_token_create(request)
  end

  def exchange_public_token(token)
    request = Plaid::ItemPublicTokenExchangeRequest.new(
      public_token: token
    )

    client.item_public_token_exchange(request)
  end

  def get_item(access_token)
    request = Plaid::ItemGetRequest.new(access_token: access_token)
    client.item_get(request)
  end

  def remove_item(access_token)
    request = Plaid::ItemRemoveRequest.new(access_token: access_token)
    client.item_remove(request)
  end

  def get_item_accounts(item)
    request = Plaid::AccountsGetRequest.new(access_token: item.access_token)
    client.accounts_get(request)
  end

  def get_item_transactions(item)
    cursor = item.next_cursor
    added = []
    modified = []
    removed = []
    has_more = true

    while has_more
      request = Plaid::TransactionsSyncRequest.new(
        access_token: item.access_token,
        cursor: cursor
      )

      response = client.transactions_sync(request)

      added += response.added
      modified += response.modified
      removed += response.removed
      has_more = response.has_more
      cursor = response.next_cursor
    end

    TransactionSyncResponse.new(added:, modified:, removed:, cursor:)
  end

  def get_item_investments(item, start_date: nil, end_date: Date.current)
    start_date = start_date || MAX_HISTORY_DAYS.days.ago.to_date
    holdings = get_item_holdings(item)
    transactions, securities = get_item_investment_transactions(item, start_date:, end_date:)

    InvestmentsResponse.new(holdings:, transactions:, securities:)
  end

  def get_item_liabilities(item)
    request = Plaid::LiabilitiesGetRequest.new({ access_token: item.access_token })
    response = client.liabilities_get(request)
    response.liabilities
  end

  private
    TransactionSyncResponse = Struct.new :added, :modified, :removed, :cursor, keyword_init: true
    InvestmentsResponse = Struct.new :holdings, :transactions, :securities, keyword_init: true

    def get_item_holdings(item)
      request = Plaid::InvestmentsHoldingsGetRequest.new({ access_token: item.access_token })
      response = client.investments_holdings_get(request)

      securities_by_id = response.securities.index_by(&:security_id)
      accounts_by_id = response.accounts.index_by(&:account_id)

      response.holdings.each do |holding|
        holding.define_singleton_method(:security) { securities_by_id[holding.security_id] }
        holding.define_singleton_method(:account) { accounts_by_id[holding.account_id] }
      end

      response.holdings
    end

    def get_item_investment_transactions(item, start_date:, end_date:)
      transactions = []
      securities = []
      offset = 0

      loop do
        request = Plaid::InvestmentsTransactionsGetRequest.new(
          access_token: item.access_token,
          start_date: start_date.to_s,
          end_date: end_date.to_s,
          options: { offset: offset }
        )

        response = client.investments_transactions_get(request)
        securities_by_id = response.securities.index_by(&:security_id)
        accounts_by_id = response.accounts.index_by(&:account_id)

        response.investment_transactions.each do |t|
          t.define_singleton_method(:security) { securities_by_id[t.security_id] }
          t.define_singleton_method(:account) { accounts_by_id[t.account_id] }
          transactions << t
        end

        securities += response.securities

        break if transactions.length >= response.total_investment_transactions
        offset = transactions.length
      end

      [ transactions, securities ]
    end

    def get_products(accountable_type)
      case accountable_type
      when "Investment"
        %w[investments]
      when "CreditCard", "Loan"
        %w[liabilities]
      else
        %w[transactions]
      end
    end

    def get_plaid_country_code(country_code)
      PLAID_COUNTRY_CODES.include?(country_code) ? country_code : "US"
    end

    def get_plaid_language(locale = "en")
      language = locale.split("-").first
      PLAID_LANGUAGES.include?(language) ? language : "en"
    end
end
