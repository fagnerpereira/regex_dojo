# frozen_string_literal: true

# Attribute submissions to the user who made them, so a learner's attempt
# history (and their latest answer per kata) can be restored across browsers.
# Nullable: rows created before this migration have no user.
ROM::SQL.migration do
  change do
    alter_table :submissions do
      add_foreign_key :user_id, :users, on_delete: :cascade, null: true
    end

    # Access path for "the most recent attempt per (user, kata)".
    add_index :submissions, %i[user_id challenge_id id],
      name: :idx_submissions_user_challenge_recent
  end
end
