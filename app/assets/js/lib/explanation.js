// The "explicação ao vivo" row shared by Desafio and Sandbox: one chip per
// token (linking to the Codex) plus a terracotta chip per active flag.
// Everything user-typed goes through escapeHTML before markup assembly.

import { escapeHTML } from "./highlight";
import { tokenize, TOKEN_COLORS, FLAG_LABELS } from "./tokenizer";

export function explanationHTML(pattern, flags, emptyText) {
  const chips = pattern
    ? tokenize(pattern)
        .map(
          ([token, label, kind]) =>
            '<a href="/codex" class="inline-flex items-center gap-2 rounded-full bg-dune-100 px-3 py-1.5 text-[12.5px] no-underline text-ink hover:bg-terra-100 transition-colors">' +
            `<span class="font-mono text-[14px] font-medium ${TOKEN_COLORS[kind] || ""}">${escapeHTML(token)}</span>${label}</a>`
        )
        .join("")
    : `<span class="text-[12.5px] text-ink/35">${escapeHTML(emptyText)}</span>`;

  const flagChips = [...flags]
    .map(
      (flag) =>
        '<span class="inline-flex items-center gap-2 rounded-full bg-terra-100 px-3 py-1.5 text-[12.5px] text-terra-800">' +
        `<span class="font-mono text-[14px] font-medium">${flag}</span>${FLAG_LABELS[flag]}</span>`
    )
    .join("");

  return chips + flagChips;
}
