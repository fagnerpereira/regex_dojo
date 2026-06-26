# frozen_string_literal: true

module RegexDojo
  class KataPool
    KATAS = [
      {
        id: "wb-01",
        belt: "white",
        title: "Your First Match",
        concept: "Literal Characters",
        lesson: "A regular expression is a pattern of characters. The simplest pattern is a literal match. The regex <code>dog</code> matches the literal characters 'd', 'o', 'g' in sequence.",
        test_string: "I have a cat, a fish, and a dog.",
        task: "Write a pattern that matches the literal word 'dog'.",
        hint: "Just type 'dog' without any other characters.",
        test_cases: [
          {input: "my dog is here", should_match: true},
          {input: "no dogs allowed", should_match: true},
          {input: "my cat is cool", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "my dog is here", expected_match: "dog"},
          {input: "no dogs allowed", expected_match: "dog"},
          {input: "my cat is cool", expected_match: nil}
        ],
        xp: 20
      },
      {
        id: "wb-02",
        belt: "white",
        title: "The Wildcard Dot",
        concept: "The Dot (.) Symbol",
        lesson: "The dot <code>.</code> is a wildcard character that matches any single character except newline. For example, <code>c.t</code> matches 'cat', 'cot', 'cut', and 'c#t'.",
        test_string: "The cat sat on the cot with a cup.",
        task: "Write a pattern that matches 'cat' and 'cot' using the wildcard dot.",
        hint: "Use a dot to replace the middle vowel: c.t",
        test_cases: [
          {input: "a cat ran by", should_match: true},
          {input: "slept on a cot", should_match: true},
          {input: "drank from a cup", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "a cat ran by", expected_match: "cat"},
          {input: "slept on a cot", expected_match: "cot"},
          {input: "drank from a cup", expected_match: nil}
        ],
        xp: 25
      },
      {
        id: "wb-03",
        belt: "white",
        title: "Picking Characters",
        concept: "Character Sets [abc]",
        lesson: "Square brackets <code>[...]</code> define a character set. It matches any single character contained within the brackets. E.g., <code>b[ae]t</code> matches 'bat' and 'bet', but not 'bit'.",
        test_string: "The bat flew over the bet.",
        task: "Match 'bat' and 'bet' using a character set, but do not match 'bit'.",
        hint: "Put the valid vowels inside square brackets: b[ae]t",
        test_cases: [
          {input: "hit with a bat", should_match: true},
          {input: "placed a bet", should_match: true},
          {input: "a tiny bit", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "hit with a bat", expected_match: "bat"},
          {input: "placed a bet", expected_match: "bet"},
          {input: "a tiny bit", expected_match: nil}
        ],
        xp: 30
      },
      {
        id: "wb-04",
        belt: "white",
        title: "Numerical Ranges",
        concept: "Ranges [0-9]",
        lesson: "Inside square brackets, you can use a hyphen <code>-</code> to specify a range of characters. E.g., <code>[0-9]</code> matches any digit, and <code>[a-z]</code> matches any lowercase letter.",
        test_string: "Agent 007 reporting for duty.",
        task: "Match any single digit between 0 and 9.",
        hint: "Use [0-9] to represent the range of digits.",
        test_cases: [
          {input: "I bought 3 apples", should_match: true},
          {input: "Agent 007", should_match: true},
          {input: "no numbers here", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "I bought 3 apples", expected_match: "3"},
          {input: "Agent 007", expected_match: "0"},
          {input: "no numbers here", expected_match: nil}
        ],
        xp: 30
      },
      {
        id: "wb-05",
        belt: "white",
        title: "Negation Sets",
        concept: "Negation [^abc]",
        lesson: "By placing a caret <code>^</code> as the first character inside square brackets, you negate the set. It matches any character NOT in the brackets. E.g., <code>[^0-9]</code> matches any non-digit.",
        test_string: "Price: $9.99.",
        task: "Match any character that is NOT a number between 0 and 9.",
        hint: "Use [^0-9] to negate the digit range.",
        test_cases: [
          {input: "X", should_match: true},
          {input: "$", should_match: true},
          {input: "5", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "X", expected_match: "X"},
          {input: "$", expected_match: "$"},
          {input: "5", expected_match: nil}
        ],
        xp: 35
      },
      {
        id: "wb-06",
        belt: "white",
        title: "Starting Line",
        concept: "Line Start Anchor (^)",
        lesson: "The caret symbol <code>^</code> when used outside square brackets acts as an anchor matching the start of the line or string. E.g., <code>^cat</code> matches 'cat' only if it appears at the very beginning.",
        test_string: "cat is sleeping, copycat.",
        task: "Match 'cat' only when it starts the line.",
        hint: "Prepend the caret anchor to the literal word: ^cat",
        test_cases: [
          {input: "cat is cute", should_match: true},
          {input: "the copycat", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "cat is cute", expected_match: "cat"},
          {input: "the copycat", expected_match: nil}
        ],
        xp: 35
      },
      {
        id: "wb-07",
        belt: "white",
        title: "Ending Line",
        concept: "Line End Anchor ($)",
        lesson: "The dollar sign <code>$</code> acts as an anchor matching the end of the line or string. E.g., <code>dog$</code> matches 'dog' only if it is the very last word.",
        test_string: "My pet dog, topdog",
        task: "Match 'dog' only when it ends the line.",
        hint: "Append the dollar anchor to the literal word: dog$",
        test_cases: [
          {input: "my pet dog", should_match: true},
          {input: "dog training", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "my pet dog", expected_match: "dog"},
          {input: "dog training", expected_match: nil}
        ],
        xp: 35
      },
      {
        id: "wb-08",
        belt: "white",
        title: "One or More",
        concept: "The Plus Quantifier (+)",
        lesson: "The plus <code>+</code> matches one or more repetitions of the preceding character or group. E.g., <code>go+al</code> matches 'goal', 'gooal', and 'gooooal'.",
        test_string: "go goal gooal goooal",
        task: "Match any string that starts with 'go', has one or more 'o's, and ends with 'al'.",
        hint: "Use the plus sign after the 'o' character: go+al",
        test_cases: [
          {input: "goal", should_match: true},
          {input: "goooal", should_match: true},
          {input: "gal", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "goal", expected_match: "goal"},
          {input: "goooal", expected_match: "goooal"},
          {input: "gal", expected_match: nil}
        ],
        xp: 40
      },
      {
        id: "wb-09",
        belt: "white",
        title: "Zero or More",
        concept: "The Star Quantifier (*)",
        lesson: "The asterisk <code>*</code> matches zero or more repetitions of the preceding character or group. E.g., <code>ab*c</code> matches 'ac', 'abc', 'abbc', and so on.",
        test_string: "ac abc abbc abbbc",
        task: "Match 'ac', 'abc', or 'abbc' using the zero-or-more star quantifier.",
        hint: "Place the star quantifier after the 'b' character: ab*c",
        test_cases: [
          {input: "ac", should_match: true},
          {input: "abc", should_match: true},
          {input: "abbc", should_match: true}
        ],
        test_cases_for_validation: [
          {input: "ac", expected_match: "ac"},
          {input: "abc", expected_match: "abc"},
          {input: "abbc", expected_match: "abbc"}
        ],
        xp: 40
      },
      {
        id: "wb-10",
        belt: "white",
        title: "Exact Counts",
        concept: "Range Quantifiers {n,m}",
        lesson: "Curly braces <code>{n,m}</code> define range repetitions. <code>{n}</code> matches exactly n times. <code>{n,}</code> matches n or more times. <code>{n,m}</code> matches between n and m times.",
        test_string: "xyz xyyz xyyyz xyyyyz",
        task: "Match 'xyyz' and 'xyyyz' using a range quantifier for 'y' between 2 and 3 repetitions.",
        hint: "Specify the range {2,3} after the 'y' character: xy{2,3}z",
        test_cases: [
          {input: "xyyz", should_match: true},
          {input: "xyyyz", should_match: true},
          {input: "xyz", should_match: false},
          {input: "xyyyyz", should_match: false}
        ],
        test_cases_for_validation: [
          {input: "xyyz", expected_match: "xyyz"},
          {input: "xyyyz", expected_match: "xyyyz"},
          {input: "xyz", expected_match: nil},
          {input: "xyyyyz", expected_match: nil}
        ],
        xp: 45
      }
    ].freeze

    def self.all
      KATAS
    end

    def self.find_by_id(id)
      KATAS.find { |k| k[:id] == id }
    end

    # Return katas suitable for blitz mode (simpler subset)
    def self.blitz_pool
      KATAS.select { |k| k[:xp] <= 35 }
    end
  end
end
