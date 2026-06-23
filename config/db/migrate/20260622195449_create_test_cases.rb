# frozen_string_literal: true

ROM::SQL.migration do
  # Add your migration here.
  #
  # See https://hanakai.org/learn/hanami/database/migrations/ for details.
  change do
    create_table :test_cases do
      primary_key :id
      foreign_key :challenge_id, :challenges, on_delete: :cascade, null: false
      column :input, :text, null: false
      column :expected_match, :text
      column :created_at, :datetime, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :updated_at, :datetime, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
