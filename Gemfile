source "https://rubygems.org"

ruby file: ".ruby-version"

# Rails
gem "rails", github: "rails/rails", branch: "main"

# Drivers
gem "pg", "~> 1.5"

# Deployment
gem "puma", ">= 5.0"
gem "bootsnap", require: false

# Assets
gem "importmap-rails"
gem "propshaft"
gem "tailwindcss-rails"
gem "lucide-rails", github: "maybe-finance/lucide-rails"

# Hotwire
gem "stimulus-rails"
gem "turbo-rails"

# Background Jobs
gem "good_job"

# Search
gem "ransack"

# Error logging
gem "stackprof"
gem "sentry-ruby"
gem "sentry-rails"

# Active Storage
gem "aws-sdk-s3", require: false
gem "image_processing", ">= 1.2"

# Other
gem "bcrypt", "~> 3.1"
gem "faraday"
gem "faraday-retry"
gem "inline_svg"
gem "octokit"
gem "pagy"
gem "rails-settings-cached"
gem "tzinfo-data", platforms: %i[ windows jruby ]

group :development, :test do
  gem "debug", platforms: %i[ mri windows ]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "dotenv-rails"
  gem "i18n-tasks"
  gem "erb_lint"
end

group :development do
  gem "hotwire-livereload"
  gem "letter_opener"
  gem "ruby-lsp-rails"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "mocha"
  gem "vcr"
  gem "webmock"
end
