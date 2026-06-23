# ActiveRecord Performance Rules

- Prefer `.pluck` and `.select` over full model instantiation for computation
- Use `.find_each` / `.find_in_batches` for large datasets (batch size 1,000)
- Use database window functions and aggregations instead of Ruby loops
- Guard against N+1 with `.includes`, `.preload`, `.eager_load`
- Use `strict_loading` in development/test to catch N+1 early
- Default JSON columns via method override: `def field; super || []; end`
