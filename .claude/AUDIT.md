# RegexDojo Codebase Audit — Hanami 3.0 Best Practices

**Date**: June 23, 2026  
**Status**: 7 tests passing ✅ | Foundation solid, architecture needs refinement  
**Grade**: C+ (good foundation, improvements needed for scalability & maintainability)

---

## What's Working Well ✅

1. **Dependency Injection (DI)**
   - Correctly using `include Deps["repos.dojo_repo"]` in actions
   - No magic Rails-style singletons; explicit dependencies
   - _Rating_: Excellent

2. **Repository Pattern**
   - Clean, explicit data layer (`dojo_repo.rb`)
   - Methods like `find_challenge_by_id`, `record_solved_kata` are well-named
   - Queries are clear and testable
   - _Rating_: Good

3. **Business Logic Separation (Validator)**
   - `Validator` class in `lib/regex_dojo/` is a standalone, testable object
   - No knowledge of HTTP/Rails concerns
   - Easy to reuse and unit test
   - _Rating_: Good

4. **Phlex Components**
   - Using Phlex for views (modern, functional approach vs Rails ERB templates)
   - Layout component is clean and composable
   - _Rating_: Good

5. **Test Structure**
   - Specs organized by type (actions, requests, lib)
   - Database cleaning strategy in place
   - RSpec configured correctly for Hanami
   - _Rating_: Good

---

## Issues & Anti-Patterns ❌

### 1. **Action Logic Too Complex** (CRITICAL)

**File**: `app/actions/kata/check.rb` (lines 12-105)

**Problem**:

- The action is a 94-line "god method" mixing concerns:
  - HTTP request parsing ✓ (action's job)
  - Regex validation ✗ (should be operation)
  - Database updates ✗ (should be operation)
  - XP calculation ✗ (should be operation)
- Duplicates regex validation logic (also in `Validator` class)
- Not using Hanami's Dry::Operation pattern

**Rails vs Hanami approach**:

- **Rails**: Often dumps all logic in controller (you complained about this!)
- **Hanami**: Should extract to Dry::Operation (monad-based, composable, testable)

**Why it matters for you**:

- An operation is self-contained, versioned, and can be called from multiple places (action, async job, CLI)
- Makes testing easier: test the operation independently, then test action's orchestration
- Better error handling via `Success()` / `Failure()` monads (which your code already includes!)

**Example refactor**:

```ruby
# lib/regex_dojo/operations/validate_kata.rb
module RegexDojo
  module Operations
    class ValidateKata
      include Dry::Monads[:result]

      def call(pattern:, test_cases:)
        # All validation logic here
        # Return Success(result) or Failure(error)
      end
    end
  end
end

# Then in action:
result = ValidateKata.new.call(pattern: pattern, test_cases: test_cases)
case result
in Success(data) then handle_success(data)
in Failure(error) then handle_failure(error)
end
```

---

### 2. **Session ID Retrieval Repeated** (MODERATE)

**Files**: `app/actions/home/index.rb`, `app/actions/kata/check.rb`

**Problem**:

```ruby
# Repeated in multiple places:
session_id = request.session[:session_id] || request.session["session_id"]
```

**Better Hanami approach**:
Extract to a helper or create a session strategy class. Hanami should use immutable sessions (symbols/strings normalized once).

---

### 3. **No Request Validation** (MODERATE)

**File**: `app/actions/kata/check.rb` (line 30)

**Problem**:

```ruby
pattern = body[:pattern].to_s.strip  # Silent coercion, no validation contract
```

Should use **Dry::Schema** or **Dry::Validation**:

```ruby
KataCheckSchema = Dry::Schema.Params do
  required(:pattern).filled(:string)
end
```

**Why**: Explicit contracts are self-documenting, and failures are traceable.

---

### 4. **Manual Error Responses** (MODERATE)

**Files**: `app/actions/kata/check.rb` (lines 16-20, 32-37, 43-49)

**Problem**:

```ruby
response.status = 404
response.format = :json
response.body = { error: "..." }.to_json
return
```

**Better Hanami approach**:
Use action's built-in error handling:

```ruby
raise NotFoundError, "Challenge not found"
```

Hanami routes error classes to HTTP status codes automatically.

---

### 5. **Duplicate XP Logic** (MODERATE)

**Files**: `app/actions/kata/check.rb` (lines 75-79) & `app/repos/dojo_repo.rb` (lines 77-81)

**Problem**:
XP calculation is defined in two places. DRY violation.

**Solution**: Define once in a constant or service.

---

### 6. **No Type Safety** (LOW)

**Files**: Throughout (`dojo_repo.rb`, actions, views)

**Problem**:
No use of Dry::Types for type coercion/validation. Relying on implicit conversions.

**Example**:

```ruby
def record_solved_kata(user_id, kata_id, xp_gained)
  # What if user_id is a string? What if xp_gained is negative?
```

**Hanami approach**:

```ruby
module Types
  include Dry::Types(default: :nominal)

  UserID = Strict::Integer.constrained(gt: 0)
  XPValue = Strict::Integer.constrained(gteq: 0)
end
```

---

### 7. **View Composition Could Be Stronger** (LOW)

**Files**: `app/views/home/dashboard.rb`, `app/views/components/*.rb`

**Problem**:
Good use of Phlex, but components could be more composable (pass blocks, slots, more explicit interfaces).

---

## Test Coverage Assessment

| Category        | Coverage   | Status                   |
| --------------- | ---------- | ------------------------ |
| Validator (lib) | ✅ 4 tests | Good                     |
| Actions         | ✅ 2 tests | Minimal (no error cases) |
| Integration     | ✅ 1 test  | Basic                    |
| **Total**       | 7 tests    | **Need more edge cases** |

**Missing tests**:

- Regex validation failures
- XP award edge cases (already solved, multiple attempts)
- Session handling edge cases
- Challenge not found error
- Invalid JSON payload

---

## Coaching Priorities (in order)

1. **Iteration 1**: Extract `kata.check` logic into `Dry::Operation` (teaches monad pattern)
2. **Iteration 2**: Add `Dry::Schema` request validation (teaches contracts)
3. **Iteration 3**: Normalize session handling with a concern (teaches composition)
4. **Iteration 4**: Type safety with `Dry::Types` (teaches domain modeling)
5. **Iteration 5**: Hanami error handling patterns (teaches framework conventions)

---

## Why This Matters for Your Goals

You want to be a **tech lead/staff engineer**. This audit teaches you:

- **Separation of concerns**: Action = orchestration, Operation = domain logic
- **Composability**: Dry::Operation can be tested, versioned, and reused
- **Contracts**: Dry::Schema ensures data integrity at system boundaries
- **Explicit over implicit**: Types and validation make assumptions visible

These patterns appear in **GitHub, GitLab, Basecamp** codebases. Learning them in Hanami (simpler than Rails) gives you a foundation to recognize them everywhere.

---

**Next**: Shall we start with **Iteration 1** (Dry::Operation extraction)?
