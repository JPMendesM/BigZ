defmodule BigzWeb.HomeLive.Index do
  @moduledoc """
  RF08 — Personal dashboard: check-in history and accumulated score per week.

  Weeks are defined as ISO weeks (Monday–Sunday) in UTC. All score figures
  are derived from the checkins→habits join — the `users.score` column is
  intentionally ignored to keep a single source of truth.
  """
  use BigzWeb, :live_view

  alias Bigz.Habits

  @checkin_limit 20
  @summary_weeks 6

  @impl true
  def mount(_params, _session, socket) do
    scope = socket.assigns.current_scope

    weekly = Habits.list_weekly_summaries(scope, @summary_weeks)
    max_pts = weekly |> Enum.map(& &1.points) |> Enum.max(fn -> 0 end)

    socket =
      socket
      |> assign(:page_title, "Visão geral")
      |> assign(:total_points, Habits.sum_user_points(scope))
      |> assign(:week_points, Habits.sum_user_points_this_week(scope))
      |> assign(:week_checkins, Habits.count_user_checkins_this_week(scope))
      |> assign(:my_habits, Habits.count_user_habits(scope))
      |> assign(:checkins, Habits.list_user_checkins(scope, @checkin_limit))
      |> assign(:weekly_summary, weekly)
      |> assign(:max_weekly_points, max(max_pts, 1))

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
            <.icon name="hero-check-circle" class="size-5" /> Registrar atividade
          </.link>
        </div>

        <%!-- Stat cards — scores derived from check-ins, not users.score --%>
        <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <.stat_card
            label="Pontuação total"
            value={@total_points}
            icon="hero-bolt"
            tone="success"
            hint="pontos de todos os check-ins"
          />
          <.stat_card
            label="Pontos esta semana"
            value={@week_points}
            icon="hero-chart-bar"
            tone="primary"
            hint="segunda a domingo, UTC"
          />
          <.stat_card
            label="Check-ins esta semana"
            value={@week_checkins}
            icon="hero-calendar"
            tone="secondary"
            hint="na semana atual"
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
          <%!-- Weekly summary bars --%>
          <div class="lg:col-span-1 rounded-box bg-base-100 border border-base-300 p-6 shadow-sm">
            <h2 class="text-lg font-bold">Últimas {length(@weekly_summary)} semanas</h2>
            <p class="text-xs text-base-content/50 mt-0.5">Pontos por semana (seg–dom, UTC)</p>

            <div class="mt-6 space-y-4">
              <div :for={week <- @weekly_summary}>
                <div class="flex justify-between items-baseline mb-1.5">
                  <span class="text-xs font-medium text-base-content/60">
                    {format_week_label(week)}
                  </span>
                  <span class="text-xs font-bold">
                    {week.points} pts · {week.count}x
                  </span>
                </div>
                <div class="h-2.5 bg-base-200 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-primary rounded-full transition-all duration-500"
                    style={"width: #{bar_pct(week.points, @max_weekly_points)}%"}
                  >
                  </div>
                </div>
              </div>
            </div>
          </div>

          <%!-- Check-in history --%>
          <div class="lg:col-span-2 rounded-box bg-base-100 border border-base-300 shadow-sm overflow-hidden">
            <div class="px-6 py-5 border-b border-base-200">
              <h2 class="text-lg font-bold">Histórico de check-ins</h2>
              <p class="text-xs text-base-content/50 mt-0.5">
                Últimos {length(@checkins)} registros — mais recente primeiro
              </p>
            </div>

            <%= if @checkins == [] do %>
              <div class="px-6 py-12 text-center">
                <span class="grid place-items-center size-14 rounded-full bg-base-200 text-base-content/40 mx-auto">
                  <.icon name="hero-calendar" class="size-7" />
                </span>
                <h3 class="font-bold mt-4">Nenhum check-in ainda</h3>
                <p class="text-sm text-base-content/50 mt-1 max-w-xs mx-auto">
                  Explore os hábitos disponíveis e registre o primeiro check-in do seu dia.
                </p>
                <.link navigate={~p"/habits"} class="btn btn-primary btn-sm mt-4 gap-2">
                  <.icon name="hero-arrow-right" class="size-4" /> Ver hábitos
                </.link>
              </div>
            <% else %>
              <ul class="divide-y divide-base-200">
                <li
                  :for={checkin <- @checkins}
                  class="flex items-center justify-between gap-3 px-6 py-3.5"
                >
                  <div class="flex items-center gap-3 min-w-0">
                    <span class={[
                      "shrink-0 px-2 py-0.5 text-[10px] font-bold tracking-wide rounded-full uppercase",
                      checkin.habit.category == "alimentação" &&
                        "bg-emerald-100 text-emerald-800 dark:bg-emerald-950 dark:text-emerald-300",
                      checkin.habit.category == "transporte" &&
                        "bg-blue-100 text-blue-800 dark:bg-blue-950 dark:text-blue-300",
                      checkin.habit.category == "energia" &&
                        "bg-amber-100 text-amber-800 dark:bg-amber-950 dark:text-amber-300",
                      checkin.habit.category == "água" &&
                        "bg-cyan-100 text-cyan-800 dark:bg-cyan-950 dark:text-cyan-300",
                      checkin.habit.category == "resíduos" &&
                        "bg-orange-100 text-orange-800 dark:bg-orange-950 dark:text-orange-300"
                    ]}>
                      {checkin.habit.category}
                    </span>
                    <span class="font-medium text-sm truncate">{checkin.habit.name}</span>
                  </div>

                  <div class="flex items-center gap-3 shrink-0">
                    <span class="flex items-center gap-1 text-xs font-bold text-success bg-success/10 px-2 py-0.5 rounded-lg border border-success/20">
                      <.icon name="hero-bolt" class="size-3" /> +{checkin.habit.points}
                    </span>
                    <span class="text-xs text-base-content/50 hidden sm:block tabular-nums">
                      {format_date(checkin.checkin_date)}
                    </span>
                  </div>
                </li>
              </ul>
            <% end %>
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

  defp bar_pct(points, max) when max > 0, do: trunc(points * 100 / max)
  defp bar_pct(_, _), do: 0

  defp format_week_label(%{week_start: date}) do
    today = Date.utc_today()
    cur_start = Date.add(today, -(Date.day_of_week(today) - 1))

    if Date.compare(date, cur_start) == :eq,
      do: "Semana atual",
      else: Calendar.strftime(date, "%d/%m")
  end

  defp format_date(%Date{} = date), do: Calendar.strftime(date, "%d/%m/%Y")
end
