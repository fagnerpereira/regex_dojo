# frozen_string_literal: true

ROM::SQL.migration do
  change do
    create_table(:users) do
      primary_key :id
      String :session_id, null: false, unique: true
      Integer :xp, default: 0, null: false
      String :belt, default: "white", null: false
      Integer :streak, default: 0, null: false
      DateTime :last_active_at, default: Sequel::CURRENT_TIMESTAMP, null: false
    end

    create_table(:progress) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      String :kata_id, null: false
      TrueClass :solved, default: false, null: false
      Integer :xp_gained, default: 0, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, null: false
    end

    create_table(:blitz_scores) do
      primary_key :id
      foreign_key :user_id, :users, null: false, on_delete: :cascade
      Integer :score, null: false
      Float :speed_multiplier, null: false
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP, null: false
    end
  end
end
