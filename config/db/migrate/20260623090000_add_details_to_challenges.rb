# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :challenges do
      add_column :concept, :string
      add_column :lesson, :text
      add_column :task, :text
    end
  end
end
