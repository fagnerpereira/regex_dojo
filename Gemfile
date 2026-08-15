# frozen_string_literal: true

source "https://rubygems.org"

gem "hanami", "~> 3.0.0.rc"
gem "hanami-assets", "~> 3.0.0.rc"
gem "hanami-action", "~> 3.0.0.rc"
gem "hanami-db", "~> 3.0.0.rc"
gem "hanami-mailer", "~> 3.0.0.rc"
gem "hanami-router", "~> 3.0.0.rc"
gem "hanami-view", "~> 3.0.0.rc"

gem "dry-types", "~> 1.7"
gem "dry-operation", ">= 1.0.1"
gem "dry-validation", "~> 1.11"
gem "i18n", "~> 1.14"
gem "puma", ">= 7.1"
gem "rake"
gem "sqlite3"
gem "phlex"

group :development do
  gem "hanami-webconsole", "~> 3.0.0.rc"
end

group :development, :test do
  gem "dotenv"
  # Syntax highlighting SQL logs
  gem "rouge"
  gem "standard", require: false
  gem "standardrb", "~> 1.0.1"
  gem "repl_type_completor", "~> 0.1.16"
  # gem "pry"
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
  gem "ruby-lsp-rspec", require: false
  gem "ruby-lsp-reek", require: false
  gem "ruby-lsp-brakeman", require: false
end

group :cli, :development do
  gem "hanami-reloader", "~> 3.0.0.rc"
end

group :cli, :development, :test do
  gem "hanami-rspec", "~> 3.0.0.rc"
end

group :test do
  # Database
  gem "database_cleaner-sequel"

  # Web integration
  gem "capybara"
  gem "rack-test"
end
