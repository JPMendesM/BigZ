# 🌊 BigZ — Surfando em Hábitos Sustentáveis

Aplicação web colaborativa desenvolvida em **Elixir** com **Phoenix LiveView**, onde usuários registram e acompanham hábitos sustentáveis do cotidiano — como reduzir o uso de plástico, economizar água ou optar por transporte ativo — acumulando pontos e visualizando o engajamento da comunidade em tempo real.

---

## 👨‍💻 Equipe

| Membro | Responsabilidade |
|--------|------------------|
| João Pedro Mendes Moreira | Módulo A — Autenticação e Perfil |
| Luiz Carlos | Módulo B — Gestão de Hábitos |
| Ricardo André | Módulo C — Registro e Acompanhamento |

---

## 📚 Disciplina

**T300 — Programação Funcional**
Universidade de Fortaleza — UNIFOR | Prof. Bruno Lopes

---

## 🎯 Objetivo

O BigZ tem como objetivo incentivar a adoção de hábitos sustentáveis por meio de uma plataforma interativa e reativa, permitindo o cadastro de hábitos ecológicos, o registro diário de check-ins, o acompanhamento de progresso via dashboard pessoal e a interação entre usuários através de um feed comunitário em tempo real.

---

## 🚀 Tecnologias Utilizadas

| Tecnologia | Função |
|------------|--------|
| Elixir | Linguagem funcional do backend |
| Phoenix Framework 1.8 | Framework web com suporte a LiveView |
| Phoenix LiveView | Interface reativa em tempo real via WebSockets |
| Ecto | ORM funcional para queries e validações |
| PostgreSQL (Supabase) | Banco de dados relacional hospedado na nuvem |
| Phoenix.PubSub | Broadcast de eventos em tempo real (Feed da Comunidade) |
| Tailwind CSS + DaisyUI | Estilização da interface |
| HEEx | Templates HTML reativos do Phoenix |
| mix phx.gen.auth | Gerador de autenticação (sessão, magic link, sudo mode) |
| PBKDF2 | Hashing seguro de senhas |

---

## ✅ Funcionalidades Implementadas

### Módulo A — Autenticação e Perfil (João Pedro)

- **RF01 — Cadastro de Usuário:** Cadastro com nome, e-mail e senha. Validações de formato de e-mail e tamanho mínimo de senha. Senha armazenada com hash PBKDF2.
- **RF02 — Login e Logout:** Login por e-mail e senha com sessão persistente (remember me). Suporte a Magic Link para confirmação de identidade. Logout seguro com invalidação de token.
- **RF03 — Página de Perfil:** Visualização e edição de nome e bio. Exibição da pontuação total acumulada, calculada em tempo real via JOIN entre check-ins e hábitos.

### Módulo B — Gestão de Hábitos (Luiz Carlos)

- **RF04 — Cadastro de Hábitos:** Criação de hábitos sustentáveis com nome, descrição, categoria (alimentação, transporte, energia, água, resíduos) e pontuação. Validações via Ecto Changesets.
- **RF05 — Listagem com Filtro por Categoria:** Listagem pública de hábitos acessível sem autenticação. Filtro dinâmico por categoria via parâmetros de URL com atualização reativa (LiveView patch).
- **RF06 — Edição e Remoção com Autorização:** Apenas o criador do hábito pode editá-lo ou removê-lo. Dupla camada de segurança: botões ocultos no template e validação de `user_id` no contexto de negócio.

### Módulo C — Registro e Acompanhamento (Ricardo André)

- **RF07 — Check-in Diário:** Registro diário de hábitos com proteção contra duplicidade no mesmo dia via `unique_constraint` no banco. Data e usuário definidos no servidor.
- **RF08 — Dashboard Pessoal:** Painel com pontuação total, pontuação semanal, contagem de check-ins e número de hábitos. Gráfico de barras com as últimas 6 semanas ISO e histórico dos últimos check-ins.
- **RF09 — Feed da Comunidade em Tempo Real:** Feed global de check-ins atualizado instantaneamente via `Phoenix.PubSub`. Privacidade garantida: apenas o nome do usuário é exibido, nunca o e-mail.

---

## 🔧 Requisitos Técnicos Atendidos

| Código | Requisito | Status |
|--------|-----------|--------|
| RT01 | Phoenix com LiveView | ✅ |
| RT02 | Banco de dados via Ecto (PostgreSQL) | ✅ |
| RT03 | Autenticação via `mix phx.gen.auth` | ✅ |
| RT04 | Layout com HEEx + Tailwind CSS | ✅ |
| RT05 | LiveView com atualização em tempo real via PubSub | ✅ |
| RT06 | Changesets com validações no Ecto | ✅ |
| RT07 | Navegação via router do Phoenix | ✅ |

---

## 🧪 Testes

O projeto possui **168 testes automatizados** cobrindo os três módulos:

```bash
# Executar todos os testes
mix test

# Executar verificação completa (compilação sem warnings + formatação + testes)
mix precommit
```

---

## 🏗️ Como Rodar o Projeto

### Pré-requisitos

- Elixir ~> 1.15
- Erlang/OTP
- Node.js (para assets)
- PostgreSQL (local ou via Supabase)

### Passo a passo

```bash
# 1. Instalar dependências
mix setup

# 2. Definir a variável de ambiente do banco de dados
#    PowerShell:
$env:DATABASE_URL="sua_url_do_postgresql"
#    Bash:
export DATABASE_URL="sua_url_do_postgresql"

# 3. Iniciar o servidor
mix phx.server
```

Acesse [http://localhost:4000](http://localhost:4000) no navegador.

---

## 📁 Estrutura de Arquivos Principais

| Camada | Arquivo | Descrição |
|--------|---------|-----------|
| Schema | `lib/bigz/accounts/user.ex` | Modelo de usuário com campos e validações |
| Schema | `lib/bigz/habits/habit.ex` | Modelo de hábito com categorias e pontuação |
| Schema | `lib/bigz/habits/checkin.ex` | Modelo de check-in com constraint de unicidade |
| Contexto | `lib/bigz/accounts.ex` | Lógica de autenticação e gerenciamento de contas |
| Contexto | `lib/bigz/habits.ex` | Lógica de hábitos, check-ins, pontuação e PubSub |
| LiveView | `lib/bigz_web/live/habit_live/index.ex` | Listagem, criação, edição e remoção de hábitos |
| LiveView | `lib/bigz_web/live/home_live/index.ex` | Dashboard pessoal com métricas e histórico |
| LiveView | `lib/bigz_web/live/community_live/index.ex` | Feed da comunidade em tempo real |
| LiveView | `lib/bigz_web/live/user_live/profile.ex` | Página de perfil do usuário |
| Layout | `lib/bigz_web/components/layouts.ex` | Shell da aplicação (sidebar, topbar, menus) |
| Router | `lib/bigz_web/router.ex` | Rotas públicas e autenticadas |
| Auth | `lib/bigz_web/user_auth.ex` | Plugs de autenticação e proteção de rotas |
