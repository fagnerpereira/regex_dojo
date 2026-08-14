// Client-side mirror of the server grading rule (RegexDojo::Graders::Regex):
// the graded value is the first participating capture group when the pattern
// has one, otherwise the full match; it must equal expected_match exactly,
// and a null expected_match means "must not match". Live feedback uses this
// so the Enviar gate and the server verdict never disagree.

export function gradedValue(match) {
  if (!match) return null;

  return match.slice(1).find((group) => group !== undefined) ?? match[0];
}

export function gradeTestCase(pattern, flags, testCase) {
  let match;

  try {
    match = new RegExp(pattern, flags).exec(testCase.input);
  } catch (_) {
    return false;
  }

  return gradedValue(match) === (testCase.expected_match ?? null);
}
