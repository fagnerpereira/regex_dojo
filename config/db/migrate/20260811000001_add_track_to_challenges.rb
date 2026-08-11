# frozen_string_literal: true

ROM::SQL.migration do
  change do
    alter_table :challenges do
      # Which learning track a challenge belongs to; resolved against the
      # compile-time registry in lib/regex_dojo/tracks.rb.
      add_column :track, String, null: false, default: "regex"
      # How the challenge is answered and graded: "pattern" (regex) or
      # "type_code" (ruby); later phases add predict_output / fill_blank.
      add_column :mode, String, null: false, default: "pattern"
      # Mode-specific content as JSON (setup, expression, expected_output,
      # accepted alternates); regex challenges keep using test_cases instead.
      add_column :payload, :text
      add_index :track
    end
  end
end
