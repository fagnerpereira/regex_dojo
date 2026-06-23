# Learnings - PixKey Testing Improvement

## Context

The `PixKey` model had a missing spec file and contained dead code referencing removed database columns.

## Patterns & Solutions

1. **Dead Code Removal**: When adding tests to a model, it's a good practice to first clean up methods that reference non-existent columns or are part of defunct flows. This prevents writing tests for broken or unused logic.
2. **Custom Associations**: The `PixKey` model relates to `Order` via `pix_key_code` and `code` instead of standard `id` based foreign keys. This required explicit `foreign_key` and `primary_key` options in the `has_many` association.
3. **UUID Generation**: The project uses a `SetUuidBeforeCreate` concern. Testing this involves building an object without a UUID and asserting it's present after saving.

## Repository Specifics

- Models use `SetUuidBeforeCreate` for UUID generation.
- Default branch uses RSpec and FactoryBot.
- Some models (like PixKey) are not associated via standard ID FKs but via attributes like code/uuid.
