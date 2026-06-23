# Regular Expressions (Regex) Educational Cheat Sheet

This document serves as the foundational curriculum and knowledge base for the RegexDojo application. It provides everything developers and learners need to know to master regular expressions in both Ruby and JavaScript.

---

## 1. Core Regex Syntax & Building Blocks

Regular expressions analyze and manipulate text based on pattern matching.

### Anchors (Position Markers)
Anchors do not match actual characters; instead, they match *positions* in the text.

*   `\A` (or `^` in single-line mode): Matches the absolute start of the string.
*   `\z` (or `$` in single-line mode): Matches the absolute end of the string.
*   `\b`: Matches a word boundary (the position between a word character and a non-word character).

### Character Classes
Character classes let you match any single character from a specific set.

*   `[aeiou]`: Matches any single vowel.
*   `[^aeiou]`: Matches any single character that is *not* a vowel.
*   `[a-z]`: Matches any lowercase letter from a to z.
*   `\d`: Matches any digit `[0-9]`.
*   `\w`: Matches any word character (alphanumeric + underscore) `[a-zA-Z0-9_]`.
*   `\s`: Matches any whitespace character (spaces, tabs, newlines).
*   `\D`, `\W`, `\S`: The uppercase versions negate the shorthand (e.g., `\D` matches any non-digit).
*   `.`: Matches any character except a newline (unless multiline flag `m` is active).

### Quantifiers (How Many Times)
Quantifiers specify how many times the preceding character or group must repeat.

*   `*`: Matches 0 or more times (Greedy).
*   `+`: Matches 1 or more times (Greedy).
*   `?`: Matches 0 or 1 time (Greedy).
*   `{n}`: Matches exactly *n* times.
*   `{n,m}`: Matches between *n* and *m* times.
*   `*?` or `+?`: Lazy (non-greedy) quantifiers. Matches the minimum number of characters necessary.

### Groups and Capturing
Grouping allows you to apply quantifiers to multiple characters or extract specific substrings.

*   `(pattern)`: Captures the matched sub-pattern into a numbered group (e.g., Group 1, Group 2).
*   `(?:pattern)`: Non-capturing group. Groups characters for quantifiers but doesn't store the match.
*   `(?<name>pattern)`: Named capture group. Stores the match in a dictionary keyed by `name`.

---

## 2. Language-Specific Regex APIs

### Ruby Regex API
In Ruby, regexes are instances of the `Regexp` class, usually created using `/pattern/` or `%r{pattern}`.

```ruby
# 1. Performance check (returns true/false)
if /^[A-Z]/.match?("Hello")
  puts "Starts with capital!"
end

# 2. Position check (returns index or nil)
index = "banana" =~ /an/  # returns 1

# 3. Data Extraction (returns MatchData or nil)
match_data = "John Doe (35)".match(/\((?<age>\d+)\)/)
if match_data
  puts match_data[:age] # => "35" (Named Capture)
  puts match_data[1]    # => "35" (Numbered Capture)
end

# 4. Global Scan (returns array of matches)
words = "one, two, three".scan(/\w+/) # => ["one", "two", "three"]
```

### JavaScript Regex API
In JavaScript, regexes are instances of `RegExp`.

```javascript
const regex = /^(?<protocol>https?):\/\//;

// 1. Boolean check
const isValid = regex.test("https://google.com"); // true

// 2. Data Extraction
const result = "https://google.com".match(regex);
if (result) {
  console.log(result.groups.protocol); // => "https" (Named Capture)
  console.log(result[1]);              // => "https" (Numbered Capture)
}

// 3. String replacement
const cleaned = "123-456".replace(/-/g, ""); // => "123456"
```

---

## 3. Lookarounds (Zero-Width Assertions)

Lookarounds match characters conditionally without "consuming" them (they don't count as part of the matched string).

*   **Positive Lookahead** `(?=...)`: Matches if the pattern is followed by `...`.
    *   `\d+(?=\s?USD)` matches `100` in `"100 USD"`.
*   **Negative Lookahead** `(?!...)`: Matches if the pattern is *not* followed by `...`.
    *   `\bcat(?!s\b)` matches `"cat"` but not `"cats"`.
*   **Positive Lookbehind** `(?<=...)`: Matches if the pattern is preceded by `...`.
    *   `(?<=\$)\d+` matches `100` in `"$100"`.
*   **Negative Lookbehind** `(?<!...)`: Matches if the pattern is *not* preceded by `...`.
    *   `(?<!-)\d+` matches positive numbers but not negative ones like `-5`.

---

## 4. Common Regex Dojo Challenges & Solutions

These are standard problems for learners to practice on inside the RegexDojo app:

### 1. Email Validation
*   **Regex**: `\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z` (Ruby) or `/^[\w+\-.]+@[a-z\d\-.]+\.[a-z]+$/i` (JS)
*   **Explanation**: Matches alphanumeric characters/dots/hyphens, followed by `@`, domain name, and a standard top-level domain.

### 2. URL Parsing (Extracting Hostname & Protocol)
*   **Regex**: `\A(?<protocol>https?):\/\/(?<domain>[a-zA-Z0-9.-]+)`
*   **Explanation**: Extracts protocol (`http` or `https`) and domain using named capture groups.

### 3. YYYY-MM-DD Date Validation
*   **Regex**: `\A\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])\z`
*   **Explanation**: Validates 4-digit year, months `01-12`, and days `01-31`.

### 4. Hex Color Codes
*   **Regex**: `\A#([a-fA-F0-9]{3}|[a-fA-F0-9]{6})\z`
*   **Explanation**: Validates a `#` symbol followed by either 3 or 6 hexadecimal characters.
