---
description: Safeguards against memory leaks and high Garbage Collection (GC) overhead
globs: **/*.rb
---
# CRuby Memory & GC Optimization Rules

High memory consumption and garbage collection sweep cycles are the primary bottlenecks in Ruby applications.

## 1. In-Place Modifications
- Mutate existing strings in-place using "bang!" methods (`gsub!`, `downcase!`, `upcase!`) instead of allocating duplicate copies on the heap :
  ```ruby
  # BAD - Allocates a brand new string on the heap
  str = str.downcase

  # GOOD - Modifies the existing heap address
  str.downcase!
  ```
- Append to strings using the shovel operator (`<<`) instead of `+=` to avoid creating intermediate string objects.

## 2. Block-to-Proc Promotion
- Never specify ampersand arguments (`&block`) in high-frequency loops or inner methods unless the block is stored for future invocation. Ampersand declarations force CRuby to promote lightweight stack blocks to heavy heap Proc objects, increasing GC pressure. Use `yield` instead :
  ```ruby
  # BAD - Converts block to a Proc object
  def execute_loop(&block)
    10_000.times { block.call }
  end

  # GOOD - Invokes block directly on the VM stack
  def execute_loop
    10_000.times { yield }
  end
  ```

## 3. Read Files Line-by-Line
- Do not read entire files into memory via `File.read` or `CSV.read`. Always process file streams line-by-line using `File.open` with `gets` or `CSV.foreach` to maintain a flat, near-zero memory profile.
