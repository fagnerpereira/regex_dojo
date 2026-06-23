# frozen_string_literal: true

ROM::SQL.migration do
  # Add your migration here.
  #
  # See https://hanakai.org/learn/hanami/database/migrations/ for details.
  change do
    create_table :submissions do
      primary_key :id
      foreign_key :challenge_id, :challenges, on_delete: :cascade, null: false
      column :user_pattern, :text, null: false
      column :is_passing, :boolean, null: false, default: false
      column :submitted_at, :datetime, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
