# frozen_string_literal: true

ROM::SQL.migration do
  change do
    add_index :progress, %i[user_id kata_id], unique: true, name: :idx_progress_user_kata_unique
  end
end
