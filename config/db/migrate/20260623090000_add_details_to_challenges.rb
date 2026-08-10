# frozen_string_literal: true

# Reconstructed from the live schema: this migration was applied (recorded in
# schema_migrations) but its file was never committed, which blocked all
# subsequent `hanami db migrate` runs and made the schema unreproducible.
ROM::SQL.migration do
  change do
    alter_table :challenges do
      add_column :concept, :string
      add_column :lesson, :text
      add_column :task, :text
    end
  end
end
