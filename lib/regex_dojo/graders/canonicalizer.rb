# frozen_string_literal: true

require "prism"

module RegexDojo
  module Graders
    # Decides whether two pieces of Ruby source say the same thing.
    #
    # The Ruby track grades by comparing the learner's answer to a reference
    # expression. Comparing the raw text would reject `arr.map { |e| e*2 }`
    # against a reference of `arr.map { |x| x * 2 }`, which is the same code.
    # So both sides are reduced to a canonical form built from Prism's AST,
    # where choices that carry no meaning — spacing, block parameter names,
    # `{}` versus `do/end` — have been normalised away.
    #
    # This module only ever PARSES. It never evaluates the source it is given,
    # which is what lets the app grade untrusted input safely.
    module Canonicalizer
      # Generous next to the regex track's 200, since a Ruby answer may carry
      # setup lines. This bounds the walk below, not Prism itself.
      MAX_SOURCE_LENGTH = 1000

      # Prism packs two formatting-only bits into every node's flags:
      # bit 0 NEWLINE, bit 1 STATIC_LITERAL. Every type-specific namespace
      # (SAFE_NAVIGATION, EXCLUDE_END, regexp options, integer base...) starts
      # at bit 2, so masking the low two bits keeps `{}` equal to `do/end`
      # while preserving every semantic distinction.
      #
      # Flags MUST be included: `deconstruct_keys` omits them entirely, and a
      # canonical form built from it alone silently accepts `1..5` for
      # `1...5`, `s.to_s` for `s&.to_s`, and `/ruby/` for `/ruby/i`.
      FORMATTING_FLAGS = 0b11

      # Nodes that open a new local-variable scope.
      SCOPE_NODES = %i[program_node def_node block_node lambda_node].freeze

      # Keys that must not reach the canonical form.
      #
      # `location` and `node_id` are byte offsets and parse-order identity, so
      # leaving them in makes the comparison length-sensitive: `x*2` would
      # differ from `x * 2` while same-length renames passed by coincidence.
      # Neither ends in `_loc`, so they need naming explicitly.
      #
      # `locals` lists a scope's variable names verbatim, which would defeat
      # the renaming below. The parameter and body nodes already encode it.
      DROPPED_KEYS = %i[location node_id locals].freeze

      # Nodes whose `name` introduces a local into the innermost scope.
      PARAMETER_NODES = %i[
        required_parameter_node optional_parameter_node rest_parameter_node
        keyword_rest_parameter_node block_parameter_node
        required_keyword_parameter_node optional_keyword_parameter_node
      ].freeze

      # Nodes whose `name` introduces a local at their own `depth`.
      LOCAL_WRITE_NODES = %i[
        local_variable_write_node local_variable_target_node
        local_variable_operator_write_node local_variable_and_write_node
        local_variable_or_write_node
      ].freeze

      # Nodes whose `name` refers to an already-introduced local.
      LOCAL_READ_NODES = %i[local_variable_read_node].freeze

      Result = Struct.new(:canonical, :error_message) do
        def ok?
          error_message.nil?
        end
      end

      class << self
        # @param source [String] Ruby source, never executed
        # @return [Result]
        def call(source)
          text = source.to_s

          return Result.new(nil, "Answer cannot be empty") if text.strip.empty?

          if text.length > MAX_SOURCE_LENGTH
            return Result.new(nil, "Answer too long (max #{MAX_SOURCE_LENGTH} characters)")
          end

          parsed = Prism.parse(text)

          # Prism reports failure but still hands back a partial tree. Walking
          # it regardless would report a syntax error as a wrong answer.
          if parsed.failure?
            return Result.new(nil, parsed.errors.first&.message || "Syntax error")
          end

          Result.new(Walker.new.canonical(parsed.value), nil)
        rescue => e
          Result.new(nil, "Could not read answer: #{e.message}")
        end

        # Unparseable source is not equivalent to anything — the caller
        # surfaces the syntax error separately.
        def equivalent?(reference, answer)
          left = call(reference)
          right = call(answer)

          return false unless left.ok? && right.ok?

          left.canonical == right.canonical
        end
      end

      # Reduces a Prism tree to nested arrays, renaming locals to positional
      # slots so that only the shape of the code survives.
      class Walker
        def initialize
          @scopes = []
        end

        def canonical(node)
          case node
          when Prism::Node then node_form(node)
          when Array then node.map { |child| canonical(child) }
          else node
          end
        end

        private

        def node_form(node)
          opens_scope = SCOPE_NODES.include?(node.type)
          @scopes.push({}) if opens_scope

          begin
            [node.type, masked_flags(node), *children(node)]
          ensure
            @scopes.pop if opens_scope
          end
        end

        def children(node)
          node.deconstruct_keys(nil).filter_map do |key, value|
            next if DROPPED_KEYS.include?(key)
            next if key.to_s.end_with?("_loc")

            [key, (key == :name && local?(node)) ? slot_for(node) : canonical(value)]
          end
        end

        def masked_flags(node)
          return 0 unless node.respond_to?(:flags, true)

          node.send(:flags) & ~FORMATTING_FLAGS
        end

        def local?(node)
          PARAMETER_NODES.include?(node.type) ||
            LOCAL_WRITE_NODES.include?(node.type) ||
            LOCAL_READ_NODES.include?(node.type)
        end

        # A local's canonical identity is the order it was introduced within
        # its scope, so `|x|` and `|e|` both become slot 0.
        def slot_for(node)
          name = node.name

          if PARAMETER_NODES.include?(node.type)
            bind(@scopes.last, name)
          elsif LOCAL_WRITE_NODES.include?(node.type)
            bind(scope_at(depth_of(node)), name)
          else
            # An unbound read (a numbered parameter, or `it`) keeps its literal
            # name rather than colliding with slot 0 of the enclosing scope.
            scope_at(depth_of(node))&.fetch(name, name) || name
          end
        end

        def bind(scope, name)
          return name if scope.nil?

          scope[name] ||= scope.size
        end

        def scope_at(depth)
          @scopes[-1 - depth] || @scopes.last
        end

        def depth_of(node)
          node.respond_to?(:depth) ? node.depth : 0
        end
      end
    end
  end
end
