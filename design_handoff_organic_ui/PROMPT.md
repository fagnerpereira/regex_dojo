# Prompt para o Claude Code — Regex Dojo · nova UI "Organic"

Como usar: copie TODO o conteúdo abaixo da linha e cole no Claude Code, aberto na raiz do repositório `fagnerpereira/regex_dojo`. Os arquivos de referência citados estão na pasta `design_handoff_organic_ui/` (coloque a pasta na raiz do repo antes).

---

Migre a UI desta aplicação (Hanami 2 + Phlex + Tailwind CSS 4) para o novo design "Organic". A referência canônica é `design_handoff_organic_ui/Regex Dojo — Protótipo.html` — um protótipo FUNCIONAL em HTML+JS puro+Tailwind 4 (via CDN de browser) que mostra look, comportamento e copy exatos de todas as telas. Ele é referência de design, não código para copiar direto: recrie nos componentes Phlex existentes (`app/views/components/`), mantendo backend, rotas e graders como estão. `README.md` na mesma pasta tem a especificação detalhada.

## 1. Tokens (Tailwind CSS 4, CSS-first — sem tailwind.config.js)
No CSS de entrada (ex.: `app/assets/css/app.css`), substitua o tema atual por:

```css
@import "tailwindcss";
@theme {
  --color-cream: #f5ead8;
  --color-sand: #ebddc5;
  --color-ink: #201e1d;
  --color-dune-100: #f9f4ed; --color-dune-200: #eee7db; --color-dune-300: #dcd3c4; --color-dune-400: #c0b6a5; --color-dune-500: #a19786; --color-dune-600: #82796a; --color-dune-700: #645c50; --color-dune-800: #474238; --color-dune-900: #2e2b25;
  --color-terra-100: #fff2eb; --color-terra-200: #ffe1d0; --color-terra-300: #ffc6a5; --color-terra-400: #f6a06b; --color-terra-500: #d67f48; --color-terra-600: #b2622d; --color-terra-700: #8c491a; --color-terra-800: #643312; --color-terra-900: #402310;
  --color-sage-100: #f0fae1; --color-sage-200: #e1eecc; --color-sage-300: #ccdbb2; --color-sage-400: #aebf92; --color-sage-500: #8fa073; --color-sage-600: #728157; --color-sage-700: #56633f; --color-sage-800: #3d472b; --color-sage-900: #272e1b;
  --font-display: "Caprasimo", serif;
  --font-body: "Figtree", sans-serif;
  --font-mono: "IBM Plex Mono", monospace;
  --radius-blob: 32px;
  --shadow-soft: 0 3px 10px rgba(46,43,37,0.16);
  --shadow-lift: 0 12px 32px rgba(46,43,37,0.22);
}
@layer base {
  html, body { background: var(--color-cream); color: var(--color-ink); font-family: var(--font-body); }
  :focus { outline: none; }
  :focus-visible { outline: 2px solid var(--color-terra-500); outline-offset: 2px; }
  ::selection { background: color-mix(in srgb, var(--color-terra-500) 30%, transparent); }
  mark { background: color-mix(in srgb, var(--color-terra-500) 30%, transparent); color: inherit; border-radius: 4px; padding: 1px 2px; }
}
```

IMPORTANTE: o fundo da página fica no `@layer base` (html/body), nunca como utility `bg-*` no body — evita a página transparente se a folha atrasar.

Modo noturno = atributo `data-dark` no `<html>` sobrescrevendo as variáveis (bloco pronto no README, seção "Dark mode"). Persistir a escolha (localStorage ou cookie). Toggle: ícone lua/sol no header.

Fontes (Google Fonts): Caprasimo 400 (display), Figtree 400/600/700 (corpo), IBM Plex Mono 400/500/600 (código). Ícones: Lucide, stroke-width 2.75, sempre inline SVG.

## 2. Terminologia e copy (PT)
- "kata" → **"desafio"** em toda a UI.
- Faixas → níveis por XP acumulado (mesmos thresholds de `lib/regex_dojo/belt_scale.rb`, só renomear labels): 0 **Novato** · 75 **Iniciante** · 160 **Intermediário** · 265 **Avançado** · 370 **Especialista**.
- Toda copy em português (o protótipo tem as strings exatas, inclusive lições e dicas dos 15 desafios). Dropdown "PT ▾" no header: estático por enquanto, sem ação.

## 3. Arquitetura de navegação
Sem barra de 5 abas. Home calma ("Início") com: header global (marca · nível · barra XP 220px · PT ▾ · toggle noturno · chip de sequência com chama) + hero "Continuar · Desafio N de 15" + 2 cards de trilha (🥋 Regex, 💎 Ruby) + 3 cards de ferramenta (Sandbox, Blitz, Codex). Páginas internas têm linha superior: "← Início" à esquerda, contexto mono no centro (ex.: "Regex · Desafio 6 de 15" + 15 pontinhos de progresso), chip à direita ("vale 25 XP").

## 4. Telas (recriar 1:1 do protótipo)
- **Início**: saudação com data, hero com alvo em mono fantasma + caret piscando, trilhas com barra e "faltam N para <nível>", ferramentas.
- **Desafio**: lição curta (1–2 frases) → tarefa em caixa sálvia com ícone info → textos de teste com highlight ao vivo (`<mark>`) e status (check sálvia / círculo vazio) → campo de padrão → "explicação ao vivo" → ações (Enviar primário desabilitado até todos os testes passarem; Enter envia; Dica secundário; "Próximo desafio" ghost após acerto). Sucesso: banner sálvia "Correto! +25 XP".
- **Sandbox**: campo de padrão + flags, explicação ao vivo, "texto de teste" (textarea) com botão **copiar** no rótulo, "resultado" com todas as ocorrências marcadas + contador. Com flag `g`, destacar todas; sem, só a primeira.
- **Blitz**: card inicial (30s, recorde) → rodando: cronômetro grande + barra + placar, desafio aleatório (revisão intercalada), avanço automático quando todos os testes passam, botão Pular → fim: resultado + "De novo".
- **Codex**: referência completa em cartões por grupo (Âncoras, Classes, Quantificadores, Grupos, Lookaround, Flags): token mono terracota + rótulo + exemplo; clique abre o exemplo no Sandbox.
- **Ruby (experimento)**: objetivo, "dado", "resultado esperado", textarea de código, Verificar/Dica, banners de acerto/erro, "formas de resolver" após acerto.

## 5. Campo de padrão (componente central — mesmo comportamento em Desafio, Sandbox e Blitz)
- `<textarea rows="1">` com **auto-crescimento** (height = scrollHeight) e quebra de linha (`white-space: pre-wrap; overflow-wrap: anywhere`) — nunca rolagem horizontal. Enter NÃO insere quebra (preventDefault; no Desafio, envia).
- Pill arredondado (radius 28px) com chips `/` circulares dentro, nas pontas; flags selecionadas aparecem em mono após a segunda `/`.
- **Flags fora do campo**: 4 botões circulares `g i m s` (toggle; ativo = terracota preenchido) com `title` no desktop; a explicação sem hover acontece na linha "explicação ao vivo" (chip terracota "g · todas as ocorrências" quando ativa).
- **Highlight de sintaxe no próprio campo** (overlay): div colorida atrás + texto do textarea transparente com caret visível; tokens coloridos: âncoras/quantificadores terracota-700, classes/grupos sálvia-800, literais tinta. Tokenizador PT no protótipo (função `tokenize`) — portar como está.
- **Explicação ao vivo**: cada token vira chip clicável que leva ao Codex; link "codex ↗" ao lado do rótulo.

## 6. Pedagogia (regras de produto — base científica no relatório `Pesquisa — Aprendizado eficiente.html`)
- Feedback imediato: highlight e status dos testes atualizam a cada tecla; no erro, mostrar o que o padrão de fato capturou.
- Placeholders NUNCA contêm a resposta; todo apoio em **Dica em 3 camadas** (conceito → esqueleto → resposta), reveladas sob demanda.
- Blitz mistura conceitos já vistos (intercalação) com o aviso "parecer mais difícil é sinal de que está funcionando".
- Sessões curtas com fim explícito; uma coisa por tela; sem cronômetro fora do Blitz.
- Streak com perdão (1 proteção/semana) — não zerar nada agressivamente.

## 7. O que NÃO mudar
Backend, rotas, graders, seeds, thresholds de XP, schema. Só views/componentes Phlex, CSS e labels (BeltScale labels → níveis PT).

## 8. Critérios de aceite
1. Todas as telas iguais ao protótipo (cores, radii, tipografia, espaçamentos, copy PT).
2. Campo de padrão: cresce ao digitar padrão longo, Enter envia, highlight colorido correto, flags togglam e aparecem após a `/`.
3. Enviar só habilita com todos os testes passando; sucesso dá +25 XP e atualiza barra/nível.
4. Modo noturno alterna e persiste; contraste ok em ambos os temas.
5. Nada de "kata"/"faixa" na UI; níveis Novato→Especialista corretos por XP.
6. Responsivo: grids colapsam em 1 coluna no mobile; alvos de toque ≥ 44px.
