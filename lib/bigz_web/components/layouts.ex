defmodule BigzWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use BigzWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders the Big Z brand mark.

  The full logo ships on a near-white background, so it must always sit on a
  light surface. The transparent icon (mascote) is safe on any surface.

  ## Examples

      <Layouts.logo />
      <Layouts.logo variant="icon" class="size-10" />
  """
  attr :variant, :string, default: "full", values: ~w(full icon)
  attr :class, :string, default: nil
  attr :rest, :global

  def logo(%{variant: "icon"} = assigns) do
    ~H"""
    <img
      src={~p"/images/big-z-logo-icon.png"}
      alt="Big Z"
      class={["object-contain", @class || "size-9"]}
      {@rest}
    />
    """
  end

  def logo(assigns) do
    ~H"""
    <img
      src={~p"/images/big-z-logo.png"}
      alt="Big Z — Surfando em Hábitos Sustentáveis"
      class={["object-contain", @class || "h-9 w-auto"]}
      {@rest}
    />
    """
  end

  @doc """
  Renders the authenticated application shell: a desktop sidebar, a compact
  topbar, a mobile drawer and the user menu.

  For unauthenticated visitors (e.g. the public habits list) it degrades to a
  light public chrome with "Entrar"/"Criar conta" actions, never exposing the
  authenticated-only navigation.
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  attr :active, :atom, default: nil, doc: "the active nav section"

  slot :inner_block, required: true

  def app(assigns) do
    user = assigns[:current_scope] && assigns.current_scope.user
    topbar_score = if user, do: Bigz.Habits.sum_user_points(assigns.current_scope), else: 0
    assigns = assigns |> assign(:user, user) |> assign(:topbar_score, topbar_score)

    ~H"""
    <div class="min-h-screen bg-base-200">
      <%!-- Desktop sidebar --%>
      <aside class="hidden lg:flex lg:flex-col lg:fixed lg:inset-y-0 lg:w-64 bg-base-100 border-r border-base-300">
        <.sidebar_content active={@active} user={@user} />
      </aside>

      <%!-- Mobile drawer --%>
      <div
        id="drawer-backdrop"
        class="hidden fixed inset-0 z-40 bg-neutral/40 lg:hidden"
        phx-click={close_drawer()}
        aria-hidden="true"
      >
      </div>
      <aside
        id="drawer-panel"
        class="hidden fixed inset-y-0 left-0 z-50 w-72 max-w-[80%] flex-col bg-base-100 border-r border-base-300 -translate-x-full lg:hidden"
      >
        <div class="flex items-center justify-end px-3 pt-3">
          <button
            type="button"
            class="btn btn-ghost btn-sm btn-circle"
            phx-click={close_drawer()}
            aria-label="Fechar menu"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </div>
        <.sidebar_content active={@active} user={@user} />
      </aside>

      <div class="lg:pl-64">
        <%!-- Topbar --%>
        <header class="sticky top-0 z-30 flex items-center gap-3 h-16 px-4 sm:px-6 bg-base-100/85 backdrop-blur border-b border-base-300">
          <button
            type="button"
            class="btn btn-ghost btn-sm btn-circle lg:hidden"
            phx-click={open_drawer()}
            aria-label="Abrir menu"
          >
            <.icon name="hero-bars-3" class="size-6" />
          </button>

          <.link navigate={~p"/inicio"} class="lg:hidden flex items-center gap-2">
            <.logo variant="icon" class="size-8" />
            <span class="font-bold tracking-tight text-base-content">Big Z</span>
          </.link>

          <div class="flex-1"></div>

          <.theme_toggle />

          <%= if @user do %>
            <div class="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-success/10 text-success font-bold text-sm border border-success/20">
              <.icon name="hero-bolt" class="size-4" />
              <span>{@topbar_score} pts</span>
            </div>

            <details class="dropdown dropdown-end">
              <summary class="btn btn-ghost gap-2 normal-case list-none">
                <span class="grid place-items-center size-8 rounded-full bg-secondary text-secondary-content text-xs font-bold uppercase">
                  {user_initials(@user)}
                </span>
                <span class="hidden sm:inline max-w-[10rem] truncate font-semibold">
                  {@user.name || @user.email}
                </span>
                <.icon name="hero-chevron-down" class="size-4 opacity-60" />
              </summary>
              <ul class="dropdown-content menu mt-2 w-60 rounded-box bg-base-100 border border-base-300 shadow-lg p-2 z-50">
                <li class="menu-title px-3 py-1">
                  <span class="block text-xs font-normal text-base-content/60 truncate">
                    {@user.email}
                  </span>
                </li>
                <li>
                  <.link navigate={~p"/profile"}>
                    <.icon name="hero-user-circle" class="size-5" /> Perfil
                  </.link>
                </li>
                <li>
                  <.link navigate={~p"/users/settings"}>
                    <.icon name="hero-cog-6-tooth" class="size-5" /> Conta e segurança
                  </.link>
                </li>
                <li>
                  <.link href={~p"/users/log-out"} method="delete" class="text-error">
                    <.icon name="hero-arrow-right-start-on-rectangle" class="size-5" /> Sair
                  </.link>
                </li>
              </ul>
            </details>
          <% else %>
            <.link navigate={~p"/users/log-in"} class="btn btn-ghost btn-sm">Entrar</.link>
            <.link navigate={~p"/users/register"} class="btn btn-primary btn-sm">Criar conta</.link>
          <% end %>
        </header>

        <main class="px-4 sm:px-6 lg:px-8 py-6 sm:py-8">
          <div class="mx-auto max-w-6xl bz-animate-fade-up">{render_slot(@inner_block)}</div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  # Shared sidebar body (desktop + mobile drawer)
  attr :active, :atom, default: nil
  attr :user, :map, default: nil

  defp sidebar_content(assigns) do
    ~H"""
    <div class="flex h-16 items-center px-5 border-b border-base-300">
      <.link navigate={~p"/inicio"} class="flex items-center" aria-label="Big Z — início">
        <.logo class="h-8 w-auto" />
      </.link>
    </div>

    <nav class="flex-1 overflow-y-auto px-3 py-4 space-y-1" aria-label="Navegação principal">
      <.nav_item
        :if={@user}
        navigate={~p"/inicio"}
        icon="hero-home"
        label="Visão geral"
        active={@active == :overview}
      />
      <.nav_item
        navigate={~p"/habits"}
        icon="hero-sparkles"
        label="Hábitos"
        active={@active == :habits}
      />
      <.nav_item
        :if={@user}
        navigate={~p"/comunidade"}
        icon="hero-user-group"
        label="Comunidade"
        active={@active == :community}
      />
      <.nav_item
        :if={@user}
        navigate={~p"/profile"}
        icon="hero-user-circle"
        label="Perfil"
        active={@active == :profile}
      />
      <.nav_item
        :if={@user}
        navigate={~p"/users/settings"}
        icon="hero-cog-6-tooth"
        label="Conta e segurança"
        active={@active == :settings}
      />
    </nav>

    <div class="px-3 py-4 border-t border-base-300">
      <%= if @user do %>
        <.link
          href={~p"/users/log-out"}
          method="delete"
          class="flex items-center gap-3 px-3 py-2.5 rounded-field text-sm font-medium text-base-content/70 hover:bg-base-200 hover:text-error transition-colors"
        >
          <.icon name="hero-arrow-right-start-on-rectangle" class="size-5" /> Sair
        </.link>
      <% else %>
        <div class="space-y-2">
          <.link navigate={~p"/users/log-in"} class="btn btn-ghost btn-sm w-full">Entrar</.link>
          <.link navigate={~p"/users/register"} class="btn btn-primary btn-sm w-full">
            Criar conta
          </.link>
        </div>
      <% end %>
    </div>
    """
  end

  attr :navigate, :string, required: true
  attr :icon, :string, required: true
  attr :label, :string, required: true
  attr :active, :boolean, default: false

  defp nav_item(assigns) do
    ~H"""
    <.link
      navigate={@navigate}
      aria-current={@active && "page"}
      class={[
        "flex items-center gap-3 px-3 py-2.5 rounded-field text-sm font-medium transition-colors bz-lift",
        @active && "bg-primary/10 text-primary",
        !@active && "text-base-content/70 hover:bg-base-200 hover:text-base-content"
      ]}
    >
      <.icon name={@icon} class="size-5 shrink-0" />
      <span>{@label}</span>
    </.link>
    """
  end

  @doc """
  Focused layout for the authentication flows (login, cadastro, confirmação).

  A brand panel on the left (desktop) and the form on the right. It never
  renders the authenticated navigation.
  """
  attr :flash, :map, required: true
  attr :current_scope, :map, default: nil
  slot :inner_block, required: true
  slot :actions, doc: "optional top-right cross-link (e.g. Register / Log in)"

  def auth(assigns) do
    ~H"""
    <div class="min-h-screen lg:grid lg:grid-cols-2 bg-base-100">
      <%!-- Brand panel --%>
      <div class="relative hidden lg:flex flex-col justify-between overflow-hidden bg-neutral text-neutral-content p-12">
        <svg
          class="absolute inset-x-0 bottom-0 w-full text-base-100/5 bz-wave"
          viewBox="0 0 1440 320"
          fill="currentColor"
          aria-hidden="true"
        >
          <path d="M0,160 C320,260 520,60 720,120 C920,180 1180,300 1440,200 L1440,320 L0,320 Z" />
        </svg>

        <.link
          navigate={~p"/"}
          class="relative flex items-center gap-3"
          aria-label="Big Z — início"
        >
          <.logo variant="icon" class="size-12 bz-float" />
          <span class="text-2xl font-extrabold tracking-tight">Big Z</span>
        </.link>

        <div class="relative space-y-4 max-w-md">
          <h2 class="text-3xl font-extrabold leading-tight">
            Pequenas escolhas criam grandes ondas de mudança.
          </h2>
          <p class="text-neutral-content/80 leading-relaxed">
            Registre hábitos, acompanhe sua evolução e transforme atitudes sustentáveis
            em parte da sua rotina.
          </p>
        </div>

        <div class="relative text-sm text-neutral-content/60">
          Constância, leveza e comunidade.
        </div>
      </div>

      <%!-- Form panel --%>
      <div class="flex flex-col min-h-screen lg:min-h-0">
        <header class="flex items-center justify-between p-5 sm:px-8">
          <.link navigate={~p"/"} class="flex items-center" aria-label="Big Z — início">
            <.logo class="h-8 w-auto" />
          </.link>
          <div class="flex items-center gap-3 text-sm">
            {render_slot(@actions)}
            <.theme_toggle />
          </div>
        </header>

        <main class="flex-1 flex items-center justify-center px-5 sm:px-8 py-8">
          <div class="w-full max-w-sm bz-animate-fade-up">{render_slot(@inner_block)}</div>
        </main>
      </div>
    </div>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center border border-base-300 bg-base-200 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border border-base-300 bg-base-100 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
        aria-label="Tema do sistema"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
        aria-label="Tema claro"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
        aria-label="Tema escuro"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  ## Drawer JS helpers

  def open_drawer(js \\ %JS{}) do
    js
    |> JS.show(
      to: "#drawer-backdrop",
      transition: {"transition-opacity ease-out duration-200", "opacity-0", "opacity-100"}
    )
    |> JS.show(
      to: "#drawer-panel",
      display: "flex",
      transition:
        {"transition-transform ease-out duration-250", "-translate-x-full", "translate-x-0"}
    )
  end

  def close_drawer(js \\ %JS{}) do
    js
    |> JS.hide(
      to: "#drawer-backdrop",
      transition: {"transition-opacity ease-in duration-150", "opacity-100", "opacity-0"}
    )
    |> JS.hide(
      to: "#drawer-panel",
      transition:
        {"transition-transform ease-in duration-200", "translate-x-0", "-translate-x-full"}
    )
  end

  ## Shared helpers

  defp user_initials(%{name: name}) when is_binary(name) and name != "" do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.slice(&1, 0, 1))
    |> String.upcase()
  end

  defp user_initials(%{email: email}) when is_binary(email),
    do: String.slice(email, 0, 2) |> String.upcase()

  defp user_initials(_), do: "BZ"
end
