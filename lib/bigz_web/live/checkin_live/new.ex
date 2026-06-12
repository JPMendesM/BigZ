defmodule BigzWeb.CheckinLive.New do
  use BigzWeb, :live_view

  alias Bigz.Habits
  alias BigzWeb.Layouts

  @impl true
  def mount(%{"habit_id" => habit_id}, _session, socket) do
    habit = Habits.get_habit!(socket.assigns.current_scope, habit_id)
    {:ok, assign(socket, habit: habit, page_title: "Registrar Check-in")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-md">
        <.header>
          Registrar Check-in
          <:subtitle>Confirme que você praticou este hábito hoje.</:subtitle>
        </.header>

        <div class="mt-6 rounded-2xl border border-base-300 bg-base-100 p-6 space-y-5 shadow-sm">
          <div>
            <span class="px-2.5 py-1 text-[11px] font-bold tracking-wide rounded-full uppercase bg-base-200 text-base-content/70">
              {@habit.category}
            </span>
            <h2 class="text-xl font-bold text-base-content mt-3">{@habit.name}</h2>
            <p class="text-sm text-base-content/60 mt-2 leading-relaxed">
              {@habit.description || "Sem descrição."}
            </p>
          </div>

          <div class="flex items-center gap-2 text-success font-extrabold text-sm bg-success/10 px-3 py-2 rounded-lg border border-success/20 w-fit">
            <.icon name="hero-bolt" class="size-4" /> +{@habit.points} pontos ao confirmar
          </div>

          <div class="border-t border-base-200 pt-4 space-y-2">
            <button
              phx-click="checkin"
              phx-disable-with="Registrando..."
              class="btn btn-primary w-full"
            >
              <.icon name="hero-check-circle" class="size-5" /> Confirmar Check-in de Hoje
            </button>
            <.link navigate={~p"/habits"} class="btn btn-ghost w-full">
              Cancelar
            </.link>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def handle_event("checkin", _params, socket) do
    case Habits.create_checkin(socket.assigns.current_scope, socket.assigns.habit) do
      {:ok, _checkin} ->
        {:noreply,
         socket
         |> put_flash(
           :info,
           "Check-in registrado! +#{socket.assigns.habit.points} pontos acumulados."
         )
         |> push_navigate(to: ~p"/habits")}

      {:error, changeset} ->
        message =
          changeset.errors
          |> Enum.map(fn {_field, {msg, _opts}} -> msg end)
          |> List.first("Não foi possível registrar o check-in. Tente novamente.")

        {:noreply, put_flash(socket, :error, message)}
    end
  end
end
