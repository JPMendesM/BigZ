defmodule BigzWeb.CommunityLive.Index do
  @moduledoc """
  RF09 — Community feed: real-time stream of check-ins from all users.

  Subscribes to the PubSub topic `Habits.community_topic()` only when the
  socket is connected (not during the initial HTTP render). New check-ins
  are prepended to the stream via handle_info; Phoenix streams deduplicate
  by DOM id so the same record never appears twice.
  """
  use BigzWeb, :live_view

  alias Bigz.Habits

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Bigz.PubSub, Habits.community_topic())
    end

    checkins = Habits.list_community_checkins()

    socket =
      socket
      |> assign(:page_title, "Comunidade")
      |> stream(:checkins, checkins)

    {:ok, socket}
  end

  @impl true
  def handle_info({:new_checkin, checkin}, socket) do
    # Prepend the new check-in at the top of the feed.
    # Phoenix streams keyed by record id ensure no duplication if the same
    # struct arrives more than once (the stream replaces the existing entry).
    {:noreply, stream_insert(socket, :checkins, checkin, at: 0)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope} active={:community}>
      <div class="space-y-6 max-w-3xl">
        <%!-- Header --%>
        <div>
          <h1 class="text-3xl font-extrabold tracking-tight">Comunidade</h1>
          <p class="text-sm text-base-content/60 mt-1">
            Atividades recentes de todos os membros — atualizadas em tempo real.
          </p>
        </div>

        <%!-- Live indicator --%>
        <div class="flex items-center gap-2 text-xs font-semibold text-success">
          <span class="relative flex size-2">
            <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-success opacity-75">
            </span>
            <span class="relative inline-flex rounded-full size-2 bg-success"></span>
          </span>
          Ao vivo
        </div>

        <%!-- Feed --%>
        <div
          id="community-feed"
          phx-update="stream"
          class="space-y-3"
        >
          <div
            id="community-empty"
            class="hidden only:block py-16 text-center rounded-box bg-base-100 border border-dashed border-base-300"
          >
            <span class="grid place-items-center size-14 rounded-full bg-base-200 text-base-content/40 mx-auto">
              <.icon name="hero-user-group" class="size-7" />
            </span>
            <h3 class="font-bold mt-4">Nenhuma atividade ainda</h3>
            <p class="text-sm text-base-content/50 mt-1">
              Seja o primeiro a registrar um check-in hoje.
            </p>
            <.link navigate={~p"/habits"} class="btn btn-primary btn-sm mt-4 gap-2">
              <.icon name="hero-arrow-right" class="size-4" /> Ver hábitos
            </.link>
          </div>

          <div
            :for={{id, checkin} <- @streams.checkins}
            id={id}
            class="bz-animate-fade-up flex items-start gap-4 rounded-box bg-base-100 border border-base-300 p-4 shadow-sm"
          >
            <%!-- User avatar (initials only — never email) --%>
            <span class="shrink-0 grid place-items-center size-10 rounded-full bg-secondary text-secondary-content text-sm font-bold uppercase">
              {user_initials(checkin.user)}
            </span>

            <div class="flex-1 min-w-0">
              <div class="flex flex-wrap items-center gap-x-2 gap-y-0.5">
                <span class="font-semibold text-sm">{display_name(checkin.user)}</span>
                <span class="text-xs text-base-content/40">registrou</span>
                <span class="font-semibold text-sm truncate">{checkin.habit.name}</span>
              </div>

              <div class="flex flex-wrap items-center gap-2 mt-2">
                <span class={[
                  "px-2 py-0.5 text-[10px] font-bold tracking-wide rounded-full uppercase",
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

                <span class="flex items-center gap-0.5 text-xs font-bold text-success bg-success/10 px-2 py-0.5 rounded-lg border border-success/20">
                  <.icon name="hero-bolt" class="size-3" /> +{checkin.habit.points} pts
                </span>

                <span class="text-xs text-base-content/40 flex items-center gap-1">
                  <.icon name="hero-clock" class="size-3" />
                  {format_datetime(checkin.inserted_at)}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  # Renders the user's initials from their name only.
  # Never falls back to the email to avoid exposing personal data.
  defp user_initials(%{name: name}) when is_binary(name) and name != "" do
    name
    |> String.split(~r/\s+/, trim: true)
    |> Enum.take(2)
    |> Enum.map_join("", &String.slice(&1, 0, 1))
    |> String.upcase()
  end

  defp user_initials(_), do: "U"

  # Returns the user's display name from their name field only.
  # Never uses email, even as a fallback, to protect user privacy.
  defp display_name(%{name: name}) when is_binary(name) and name != "", do: name
  defp display_name(_), do: "Usuário"

  defp format_datetime(%DateTime{} = dt) do
    Calendar.strftime(dt, "%d/%m/%Y %H:%M")
  end

  defp format_datetime(other), do: to_string(other)
end
