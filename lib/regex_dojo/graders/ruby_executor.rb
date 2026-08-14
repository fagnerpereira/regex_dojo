# frozen_string_literal: true

require "open3"
require "rbconfig"

module RegexDojo
  module Graders
    # Runs a learner's Ruby answer in a THROWAWAY SUBPROCESS and returns the
    # inspect form of its final value.
    #
    # This is the deliberate counterweight to Canonicalizer's parse-only rule:
    # structure matching alone rejects every correct-but-unanticipated answer,
    # which reads as "your right answer is wrong" to a learner. Execution is
    # the fallback judge — but it IS arbitrary code execution, so it runs:
    #   - in a separate OS process (`ruby --disable-gems -e`), never in-app;
    #   - under a hard wall-clock timeout, killed with SIGKILL on breach;
    #   - only in development/test — hard-disabled in production, where the
    #     structural verdict stands alone. Personal-learning-tool trade-off,
    #     documented in docs/IMPROVEMENTS.md.
    module RubyExecutor
      TIMEOUT_SECONDS = 2

      Outcome = Struct.new(:output, :error_message) do
        def ok?
          error_message.nil?
        end
      end

      class << self
        def available?
          !(defined?(Hanami) && Hanami.respond_to?(:env?) && Hanami.env?(:production))
        end

        # @param setup_lines [Array<String>] the kata's given bindings
        # @param answer [String] the learner's expression
        # @return [Outcome] output holds the final value's #inspect on success
        def call(setup_lines, answer)
          script = <<~RUBY
            #{setup_lines.join("\n")}
            print((
              #{answer}
            ).inspect)
          RUBY

          run_subprocess(script)
        end

        private

        def run_subprocess(script)
          Open3.popen3(RbConfig.ruby, "--disable-gems", "-e", script) do |stdin, stdout, stderr, wait_thr|
            stdin.close

            unless wait_thr.join(TIMEOUT_SECONDS)
              Process.kill("KILL", wait_thr.pid)
              wait_thr.join
              return Outcome.new(nil, "Your code took too long to run (over #{TIMEOUT_SECONDS}s) — check for infinite loops")
            end

            output = stdout.read
            error = stderr.read

            if wait_thr.value.success?
              Outcome.new(output, nil)
            else
              Outcome.new(nil, "Your code raised: #{first_error_line(error)}")
            end
          end
        rescue SystemCallError => e
          Outcome.new(nil, "Could not run your code: #{e.message}")
        end

        # "-e:3:in 'block': undefined method ..." → "undefined method ..."
        def first_error_line(stderr_text)
          line = stderr_text.lines.first.to_s.strip
          line.sub(/\A-e:\d+(:in [^:]+)?:\s*/, "")
        end
      end
    end
  end
end
