# BigZ — Surfando em Hábitos Sustentáveis

**T300 — Programação Funcional**
Universidade de Fortaleza — UNIFOR
Prof. Bruno Lopes

---

## Equipe e Divisão de Módulos

| Membro | Módulo | Requisitos Funcionais |
|--------|--------|-----------------------|
| João Pedro Mendes Moreira | Módulo A — Autenticação e Perfil | RF01, RF02, RF03 |
| Luiz Carlos | Módulo B — Gestão de Hábitos | RF04, RF05, RF06 |
| Ricardo André | Módulo C — Registro e Acompanhamento | RF07, RF08, RF09 |

---

## Link do Vídeo

> [INSERIR LINK DO VÍDEO AQUI]

---

## Repositório

> [INSERIR LINK DO REPOSITÓRIO AQUI]

---

## Tecnologias Utilizadas

| Tecnologia | Finalidade |
|------------|-----------|
| Elixir 1.19 + Phoenix 1.8 | Framework principal da aplicação |
| Phoenix LiveView 1.1 | Interface reativa sem JavaScript manual |
| Ecto + PostgreSQL (Supabase) | Persistência e consultas relacionais |
| HEEx | Templating dos componentes e layouts |
| Tailwind CSS v4 + DaisyUI 5 | Estilização e sistema de design |
| Phoenix.PubSub | Atualizações em tempo real (RF09 / RT05) |
| mix phx.gen.auth | Geração do sistema de autenticação (RT03) |

---

## Requisitos Implementados

### Requisitos Técnicos Obrigatórios (RT01–RT07) — Equipe

| Código | Requisito | Status | Arquivo principal |
|--------|-----------|--------|-------------------|
| RT01 | Phoenix com LiveView | Concluído | `lib/bigz_web/router.ex` |
| RT02 | Banco de dados via Ecto (PostgreSQL) | Concluído | `lib/bigz/habits.ex`, `lib/bigz/accounts.ex` |
| RT03 | Autenticação via mix phx.gen.auth | Concluído | `lib/bigz_web/user_auth.ex` |
| RT04 | Layout com HEEx + Tailwind CSS | Concluído | `lib/bigz_web/components/layouts.ex` |
| RT05 | LiveView com atualização em tempo real via PubSub | Concluído | `lib/bigz_web/live/community_live/index.ex` |
| RT06 | Changesets com validações no Ecto | Concluído | `lib/bigz/habits/habit.ex`, `lib/bigz/habits/checkin.ex` |
| RT07 | Navegação entre LiveViews via router Phoenix | Concluído | `lib/bigz_web/router.ex` |

---

### Módulo A — João Pedro Mendes Moreira

| Código | Requisito | Status | Arquivo principal |
|--------|-----------|--------|-------------------|
| RF01 | Cadastro com nome, e-mail e senha via mix phx.gen.auth | Concluído | `lib/bigz/accounts/user.ex` |
| RF02 | Login e logout com sessão persistente | Concluído | `lib/bigz_web/user_auth.ex` |
| RF03 | Perfil com nome, bio editável e pontuação total acumulada | Concluído | `lib/bigz_web/live/user_live/profile.ex` |

---

### Módulo B — Luiz Carlos

| Código | Requisito | Status | Arquivo principal |
|--------|-----------|--------|-------------------|
| RF04 | Cadastro de hábitos com nome, descrição, categoria e pontuação | Concluído | `lib/bigz/habits/habit.ex` |
| RF05 | Listagem de hábitos com filtro por categoria | Concluído | `lib/bigz_web/live/habit_live/index.ex` |
| RF06 | Edição e remoção de hábitos pelo próprio usuário | Concluído | `lib/bigz/habits.ex` |

---

### Módulo C — Ricardo André

| Código | Requisito | Status | Arquivo principal |
|--------|-----------|--------|-------------------|
| RF07 | Check-in diário com impedimento de duplicidade no mesmo dia | Concluído | `lib/bigz/habits.ex`, `lib/bigz/habits/checkin.ex` |
| RF08 | Dashboard pessoal com histórico de check-ins e pontuação semanal | Concluído | `lib/bigz_web/live/home_live/index.ex` |
| RF09 | Feed da comunidade em tempo real via PubSub | Concluído | `lib/bigz_web/live/community_live/index.ex` |

---

## Notas Técnicas de Implementação

### RF07 — Segurança do check-in
O `user_id` é sempre extraído de `current_scope` (sessão autenticada) — nunca aceito como entrada do usuário. A data é definida exclusivamente no servidor via `Date.utc_today()`. A unicidade é garantida por índice composto no banco (`user_id + habit_id + checkin_date`) e pelo changeset Ecto, que retorna a mensagem "Você já registrou este hábito hoje." em caso de duplicidade.

### RF08 — Pontuação sem campo redundante
A pontuação do usuário é calculada via `JOIN` entre `checkins` e `habits` (`SUM(h.points)`). O campo `score` da tabela `users` existe no schema mas propositalmente nunca é atualizado, evitando duas fontes de verdade no banco de dados.

### RF09 — Atualização em tempo real
O `CommunityLive.Index` subscreve ao tópico PubSub `"checkins:community"` somente quando o socket WebSocket está conectado (`connected?(socket)`), evitando subscriptions durante o render HTTP inicial. O `handle_info/2` usa `stream_insert` com `at: 0` para prepor o check-in ao topo. O mecanismo de Phoenix Streams garante deduplicação por DOM id.

---

## Declaração de Uso de Inteligência Artificial

A equipe utilizou a ferramenta **Claude Code (Anthropic)** como assistente de desenvolvimento durante a implementação do projeto. O uso foi declarado conforme exigido pelo enunciado.

Os arquivos individuais com os prompts e respostas geradas pela IA estão anexados separadamente, um por membro da equipe, conforme especificado nas instruções de entrega (item 1c).

| Membro | Arquivo de prompts |
|--------|--------------------|
| João Pedro Mendes Moreira | `prompts_joao_pedro.pdf` |
| Luiz Carlos | `prompts_luiz.pdf` |
| Ricardo André | `prompts_ricardo.pdf` |
