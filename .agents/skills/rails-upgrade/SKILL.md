---
name: rails-upgrade
description: >
  Apply workflows for upgrading Rails or major gem dependencies, including dual-boot setups,
  conditional spec runs, sequence planning, and resolving deprecation conflicts. Use when
  upgrading Rails or primary dependencies.
---

# Skill: Dual-Boot Rails Upgrade Guide

Apply this workflow whenever upgrading Rails or major gem dependencies.

## Phase-by-Phase Process

1. **Audit Base Defaults**: Verify that `config.load_defaults` aligns with your current Rails version.
2. **Install Dual Boot Gem**: Add `next_rails` to the `Gemfile` to enable dual-boot environments.
3. **Plan Version Sequence**: Always execute upgrades one minor hop at a time (e.g., 7.0 -> 7.1 -> 7.2 -> 8.0).
4. **Run Conditional Specs**: Execute the test suite using `RAILS_NEXT=1 bundle exec rspec` alongside your legacy run to compare outcomes.
5. **Resolve Conflicts**: Address deprecation warnings individually before merging changes into main.
