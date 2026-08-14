# Handoff: Regex Dojo — nova UI "Organic"

## Overview
Redesign completo da UI do Regex Dojo (app Hanami 2 + Phlex + Tailwind CSS 4) para o tema Organic: creme e areia, terracota + sálvia, Caprasimo/Figtree/IBM Plex Mono, formas arredondadas, uma coisa por tela. Objetivo: aprender regex digitando de memória, do Novato ao Especialista, com o mínimo de ruído (confortável para TDAH, crianças e adultos). Copy em português.

## Sobre os arquivos de design
Os arquivos deste pacote são **referências de design em HTML** — protótipos que mostram aparência e comportamento pretendidos, não código de produção. A tarefa é **recriar estas telas no codebase existente** (Hanami/Phlex/Tailwind 4), usando os padrões do repositório. `PROMPT.md` é o roteiro pronto para colar no Claude Code.

- `Regex Dojo — Protótipo.html` — protótipo funcional (todas as telas, navegação por hash, avaliação de regex ao vivo, copy final). Abra no navegador; é a fonte da verdade visual e de comportamento.
- `Pesquisa — Aprendizado eficiente.html` — relatório com a base científica das decisões (retrieval practice, espaçamento, intercalação, worked examples, feedback imediato, TDAH, gamificação humana) e a trilha proposta de 10 módulos.
- `styles.css` — tokens do design system Organic original (referência histórica; os tokens Tailwind 4 prontos estão no PROMPT.md).

## Fidelidade
**Hi-fi.** Cores, tipografia, espaçamentos, radii, estados e copy são finais — recriar pixel-perfect com os padrões do codebase.

## Telas
Detalhadas no PROMPT.md §3–4; todas presentes e navegáveis no protótipo: Início (`#/`), Desafio (`#/desafio`), Sandbox (`#/sandbox`), Blitz (`#/blitz`, 3 estados), Codex (`#/codex`), Ruby (`#/ruby`).

## Interações e comportamento
- Campo de padrão universal: textarea auto-crescente com quebra, chips `/` internos, flags externas g/i/m/s, highlight de sintaxe por overlay, Enter envia (nunca quebra linha). PROMPT.md §5.
- Avaliação ao vivo a cada tecla: `<mark>` no trecho casado de cada texto de teste; status check/círculo; Enviar habilita só com tudo passando.
- Explicação ao vivo: tokenizador PT → chips clicáveis (→ Codex); flags ativas viram chips terracota (solução sem hover para mobile).
- Dica em 3 camadas (conceito → esqueleto → resposta); placeholders neutros, nunca a resposta.
- Sucesso: banner sálvia + "+25 XP", barra XP anima, pontinho do desafio vira sálvia; "Próximo desafio".
- Blitz: 30s, desafio aleatório, avanço automático ao acertar, Pular, recorde persistido.
- Sandbox: botão "copiar" no texto de teste (clipboard, feedback "copiado!"); com `g` marca todas as ocorrências + contador.
- Modo noturno: toggle lua/sol no header; `data-dark` no `<html>` sobrescreve as variáveis de cor; persiste.
- Decisão em aberto (documentada): chips `/` podem migrar para FORA do campo numa próxima iteração — avaliar na implementação.

## Estado
Protótipo persiste em localStorage (`rd_proto`: xp, solved[], cur, streak; `rd_dark`; `rd_blitz`). Na aplicação real, xp/solved/streak já vêm do banco (users, progress, submissions); manter. `rd_dark` pode ficar client-side.

## Dark mode (variáveis)
```css
html[data-dark] {
  --color-cream:#282420; --color-sand:#35302a; --color-ink:#f2ead9;
  --color-dune-100:#2f2b25; --color-dune-200:#3b362e; --color-dune-300:#4a443a; --color-dune-700:#c0b6a5; --color-dune-800:#dcd3c4;
  --color-terra-100:#42301f; --color-terra-600:#f6a06b; --color-terra-700:#f6a06b; --color-terra-800:#ffc6a5;
  --color-sage-100:#333a26; --color-sage-200:#3d472b; --color-sage-700:#ccdbb2; --color-sage-800:#e1eecc; --color-sage-900:#f0fae1;
  --shadow-soft:0 3px 10px rgba(0,0,0,0.4); --shadow-lift:0 12px 32px rgba(0,0,0,0.5);
}
```

## Design tokens
Bloco `@theme` completo (cores cream/sand/ink + rampas dune/terra/sage 100–900, fontes, radius-blob 32px, sombras) no PROMPT.md §1 — copiar dali. Espaçamento: escala padrão do Tailwind. Radii: pills 999px/28px, cards `--radius-blob` (32px+), inputs 22–28px.

## Níveis (ex-faixas)
XP acumulado, thresholds de `lib/regex_dojo/belt_scale.rb` (inalterados): 0 Novato · 75 Iniciante · 160 Intermediário · 265 Avançado · 370 Especialista.

## Assets
- Google Fonts: Caprasimo 400; Figtree 400/600/700; IBM Plex Mono 400/500/600.
- Ícones: Lucide (https://lucide.dev), stroke 2.75, inline SVG (chama, raio, frasco, livro, setas, check, lua/sol, copiar).
- Emojis 🥋 💎 apenas como identidade das trilhas (vêm de `lib/regex_dojo/tracks.rb`).

## Arquivos
- `PROMPT.md` — roteiro de migração para o Claude Code (passo a passo + critérios de aceite)
- `Regex Dojo — Protótipo.html` — protótipo funcional (fonte da verdade)
- `Pesquisa — Aprendizado eficiente.html` — fundamentação científica + trilha de 10 módulos
- `styles.css` — tokens Organic originais (referência)
