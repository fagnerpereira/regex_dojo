// Portuguese regex tokenizer, ported as-is from the Organic prototype. Feeds
// both the in-field syntax highlight and the "explicação ao vivo" chips.

import { escapeHTML } from "./highlight";

export const FLAG_LABELS = {
  g: "todas as ocorrências",
  i: "ignora maiúsculas/minúsculas",
  m: "multilinha: ^ e $ valem por linha",
  s: "o ponto também casa quebra de linha",
};

// Token kinds → text color classes (anchors/quantifiers terracotta,
// classes/groups sage, literals ink).
export const TOKEN_COLORS = {
  anc: "text-terra-700",
  cls: "text-sage-800",
  qnt: "text-terra-700",
  grp: "text-sage-800",
  lit: "text-ink",
  warn: "text-terra-600",
};

const QUANTIFIERS = { "+": "um ou mais", "*": "zero ou mais", "?": "opcional" };
const ESCAPES = {
  d: "dígito",
  D: "não dígito",
  w: "caractere de palavra",
  W: "não palavra",
  s: "espaço",
  S: "não espaço",
  b: "borda de palavra",
  B: "não borda",
};

export function tokenize(pattern) {
  const out = [];
  let i = 0;
  let literal = "";

  const flush = () => {
    if (literal) {
      out.push([literal, "literal", "lit"]);
      literal = "";
    }
  };

  while (i < pattern.length) {
    const c = pattern[i];

    if (c === "\\") {
      const next = pattern[i + 1];
      if (next === undefined) {
        flush();
        out.push(["\\", "incompleto", "warn"]);
        i++;
        continue;
      }
      flush();
      out.push(["\\" + next, ESCAPES[next] || "literal escapado", ESCAPES[next] ? "cls" : "lit"]);
      i += 2;
      continue;
    }

    if (c === "[") {
      let j = i + 1;
      const negated = pattern[j] === "^";
      while (j < pattern.length && pattern[j] !== "]") {
        if (pattern[j] === "\\") j++;
        j++;
      }
      flush();
      out.push([pattern.slice(i, Math.min(j + 1, pattern.length)), negated ? "conjunto negado" : "conjunto", "cls"]);
      i = j + 1;
      continue;
    }

    if (c === "(") {
      let label = "grupo de captura";
      let length = 1;
      if (pattern.startsWith("(?:", i)) {
        label = "grupo sem captura";
        length = 3;
      } else if (pattern.startsWith("(?=", i)) {
        label = "lookahead";
        length = 3;
      } else if (pattern.startsWith("(?!", i)) {
        label = "lookahead negativo";
        length = 3;
      } else if (pattern.startsWith("(?<=", i)) {
        label = "lookbehind";
        length = 4;
      } else if (pattern.startsWith("(?<!", i)) {
        label = "lookbehind negativo";
        length = 4;
      }
      flush();
      out.push([pattern.slice(i, i + length), label, "grp"]);
      i += length;
      continue;
    }

    if (c === ")") {
      flush();
      out.push([")", "fecha grupo", "grp"]);
      i++;
      continue;
    }

    if (c === "{") {
      const j = pattern.indexOf("}", i);
      if (j > 0) {
        flush();
        out.push([pattern.slice(i, j + 1), "repetições", "qnt"]);
        i = j + 1;
        continue;
      }
    }

    if (QUANTIFIERS[c]) {
      flush();
      const previous = out[out.length - 1];
      if (c === "?" && previous && previous[2] === "qnt") {
        previous[0] += "?";
        previous[1] += " (lazy)";
        i++;
        continue;
      }
      out.push([c, QUANTIFIERS[c], "qnt"]);
      i++;
      continue;
    }

    if (c === "^") {
      flush();
      out.push(["^", "início da linha", "anc"]);
      i++;
      continue;
    }
    if (c === "$") {
      flush();
      out.push(["$", "fim da linha", "anc"]);
      i++;
      continue;
    }
    if (c === "|") {
      flush();
      out.push(["|", "alternância (ou)", "grp"]);
      i++;
      continue;
    }
    if (c === ".") {
      flush();
      out.push([".", "qualquer caractere", "cls"]);
      i++;
      continue;
    }

    literal += c;
    i++;
  }

  flush();
  return out;
}

// Colored spans mirrored behind the transparent-text pattern field.
export function highlightHTML(pattern) {
  return tokenize(pattern)
    .map(([token, , kind]) => `<span class="${TOKEN_COLORS[kind] || ""}">${escapeHTML(token)}</span>`)
    .join("");
}
