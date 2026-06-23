# frozen_string_literal: true

ROM::SQL.migration do
  # Add your migration here.
  #
  # See https://hanakai.org/learn/hanami/database/migrations/ for details.
  change do
    create_table :challenges do
      primary_key :id
      column :title, :string, null: false
      column :difficulty, :string, null: false
      column :description, :text, null: false
      column :hint, :text
      column :created_at, :datetime, null: false, default: Sequel::CURRENT_TIMESTAMP
      column :updated_at, :datetime, null: false, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
