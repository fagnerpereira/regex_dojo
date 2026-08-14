// Shared HTML-escaping and match-highlighting helpers. One home for logic
// that used to live copied inside dojo_controller and sandbox_controller.

export function escapeHTML(text) {
  return String(text)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;");
}

// Wrap the single given match (a String#match result) in <mark>.
export function markFirst(text, match) {
  if (!match || !match[0].length) return escapeHTML(text);

  const start = match.index;
  const end = start + match[0].length;

  return (
    escapeHTML(text.slice(0, start)) +
    `<mark>${escapeHTML(match[0])}</mark>` +
    escapeHTML(text.slice(end))
  );
}

// Wrap every occurrence in <mark>, guarding zero-length matches so a pattern
// like `a*` cannot loop forever. Returns the HTML and the occurrence count.
export function markAll(text, regex) {
  regex.lastIndex = 0;

  const parts = [];
  let lastIndex = 0;
  let count = 0;
  let match;

  while ((match = regex.exec(text)) !== null) {
    if (match.index === regex.lastIndex) {
      regex.lastIndex++;
      continue;
    }

    if (match.index > lastIndex) parts.push(escapeHTML(text.slice(lastIndex, match.index)));
    parts.push(`<mark>${escapeHTML(match[0])}</mark>`);
    lastIndex = regex.lastIndex;
    count++;
  }

  if (lastIndex < text.length) parts.push(escapeHTML(text.slice(lastIndex)));

  return { html: parts.length > 0 ? parts.join("") : escapeHTML(text), count };
}
