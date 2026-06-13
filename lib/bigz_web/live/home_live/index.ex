defmodule BigzWeb.HomeLive.Index do
  @moduledoc """
  Authenticated overview ("Visão geral").

  Uses only real data already available (user score and counts derived from the
  Habits context). The statistic cards are reusable and ready to receive the
  weekly metrics of the future dashboard (RF08).
  """
  use BigzWeb, :live_view

  alias Bigz.Habits

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    socket =
      socket
      |> assign(:page_title, "Visão geral")
      |> assign(:total_habits, Habits.count_habits())
      |> assign(:my_habits, Habits.count_user_habits(scope))
      |> assign(:my_checkins, Habits.count_user_checkins(scope))
      |> assign(:checkins_today, Habits.count_user_checkins_today(scope))

    {:ok, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active={:overview}>
      <div class="space-y-8">
        <%!-- Greeting --%>
        <div class="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4">
          <div>
            <p class="text-sm text-base-content/50">
              {greeting()}, que bom ter você de volta.
            </p>
            <h1 class="text-3xl font-extrabold tracking-tight mt-1">
              Olá, {first_name(@current_scope.user)}
            </h1>
          </div>
          <.link navigate={~p"/habits"} class="btn btn-primary gap-2">
            <.icon name="hero-check-circle" class="size-5" /> Registrar uma atividade
          </.link>
        </div>

        <%!-- Stats --%>
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <.stat_card
            label="Pontuação total"
            value={@current_scope.user.score || 0}
            icon="hero-bolt"
            tone="success"
            hint="pontos acumulados"
          />
          <.stat_card
            label="Check-ins hoje"
            value={@checkins_today}
            icon="hero-calendar"
            tone="primary"
            hint="registrados hoje"
          />
          <.stat_card
            label="Total de check-ins"
            value={@my_checkins}
            icon="hero-check-circle"
            tone="secondary"
            hint="ao longo da jornada"
          />
          <.stat_card
            label="Seus hábitos"
            value={@my_habits}
            icon="hero-sparkles"
            tone="accent"
            hint="criados por você"
          />
        </div>

        <div class="grid gap-6 lg:grid-cols-3">
          <%!-- Next step / quick actions --%>
          <div class="lg:col-span-2 rounded-box bg-base-100 border border-base-300 p-6 shadow-sm">
            <h2 class="text-lg font-bold">Seu próximo passo</h2>

            <%= if @total_habits == 0 do %>
              <div class="mt-4 text-center py-8">
                <span class="grid place-items-center size-14 rounded-full bg-primary/10 text-primary mx-auto">
                  <.icon name="hero-sparkles" class="size-7" />
                </span>
                <h3 class="font-bold mt-4">Comece criando um hábito</h3>
                <p class="text-sm text-base-content/60 mt-1 max-w-sm mx-auto">
                  Ainda não há hábitos cadastrados. Crie o primeiro e dê início à sua rotina
                  sustentável.
                </p>
                <.link navigate={~p"/habits"} class="btn btn-primary btn-sm mt-4 gap-2">
                  <.icon name="hero-plus" class="size-4" /> Criar hábito
                </.link>
              </div>
            <% else %>
              <p class="text-sm text-base-content/60 mt-1">
                Explore o catálogo, registre os hábitos que praticou hoje e some pontos.
              </p>
              <div class="mt-5 grid sm:grid-cols-2 gap-3">
                <.link
                  navigate={~p"/habits"}
                  class="bz-lift flex items-center gap-3 rounded-field border border-base-300 p-4 hover:bg-base-200"
                >
                  <span class="grid place-items-center size-10 rounded-field bg-primary/10 text-primary">
                    <.icon name="hero-sparkles" class="size-5" />
                  </span>
                  <span>
                    <span class="block font-semibold">Ver hábitos</span>
                    <span class="block text-xs text-base-content/50">
                      {@total_habits} disponíveis
                    </span>
                  </span>
                </.link>
                <.link
                  navigate={~p"/profile"}
                  class="bz-lift flex items-center gap-3 rounded-field border border-base-300 p-4 hover:bg-base-200"
                >
                  <span class="grid place-items-center size-10 rounded-field bg-secondary/10 text-secondary">
                    <.icon name="hero-user-circle" class="size-5" />
                  </span>
                  <span>
                    <span class="block font-semibold">Editar perfil</span>
                    <span class="block text-xs text-base-content/50">nome e bio</span>
                  </span>
                </.link>
              </div>
            <% end %>
          </div>

          <%!-- Profile summary --%>
          <div class="rounded-box bg-base-100 border border-base-300 p-6 shadow-sm">
            <h2 class="text-lg font-bold">Seu perfil</h2>
            <div class="mt-4 flex items-center gap-3">
              <span class="grid place-items-center size-12 rounded-full bg-secondary text-secondary-content font-bold uppercase">
                {initials(@current_scope.user)}
              </span>
              <div class="min-w-0">
                <p class="font-semibold truncate">{@current_scope.user.name}</p>
                <p class="text-sm text-base-content/50 truncate">{@current_scope.user.email}</p>
              </div>
            </div>
            <div class="mt-4 flex items-center justify-between rounded-field bg-base-200 px-4 py-3">
              <span class="text-sm text-base-content/60">Pontuação</span>
              <span class="font-bold text-success flex items-center gap-1">
                <.icon name="hero-bolt" class="size-4" />{@current_scope.user.score || 0}
              </span>
            </div>
            <.link navigate={~p"/profile"} class="btn btn-ghost btn-sm w-full mt-4">
              Ver perfil completo
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  defp greeting do
    case Time.utc_now().hour do
      h when h in 5..11 -> "Bom dia"
      h when h in 12..17 -> "Boa tarde"
      _ -> "Boa noite"
    end
  end

  defp first_name(%{name: name}) when is_binary(name) and name != "" do
    name |> String.split(~r/\s+/, trim: true) |> List.first()
  end

  defp first_name(%{email: email}), do: email |> String.split("@") |> List.first()

  defp initials(%{name: name}) when is_binary(name) and name != "" do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.slice(&1, 0, 1))
    |> String.upcase()
  end

  defp initials(%{email: email}), do: email |> String.slice(0, 2) |> String.upcase()
end
