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
    <Layouts.app flash={@flash} current_scope={@current_scope} active={:habits}>
      <div class="mx-auto max-w-md">
        <%!-- Breadcrumb / back --%>
        <nav class="flex items-center gap-1.5 text-sm text-base-content/50 mb-4" aria-label="Trilha">
          <.link navigate={~p"/habits"} class="hover:text-base-content transition-colors">
            Hábitos
          </.link> <.icon name="hero-chevron-right" class="size-4" />
          <span class="text-base-content/70 font-medium">Registrar Check-in</span>
        </nav>
        
        <.link
          navigate={~p"/habits"}
          class="inline-flex items-center gap-1.5 text-sm text-base-content/60 hover:text-base-content transition-colors mb-4"
        >
          <.icon name="hero-arrow-left" class="size-4" /> Voltar aos hábitos
        </.link>
        <div>
          <h1 class="text-2xl font-extrabold tracking-tight">Registrar Check-in</h1>
          
          <p class="text-sm text-base-content/60 mt-1">
            Confirme que você praticou este hábito hoje.
          </p>
        </div>
        
        <div class="mt-6 rounded-box border border-base-300 bg-base-100 p-6 space-y-5 shadow-sm">
          <div>
            <span class="px-2.5 py-1 text-[11px] font-bold tracking-wide rounded-full uppercase bg-base-200 text-base-content/70 capitalize">
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
          
          <div class="flex items-center gap-2 text-xs text-base-content/50">
            <.icon name="hero-calendar" class="size-4" />
            Registro referente a hoje ({Date.utc_today()}).
          </div>
          
          <div class="border-t border-base-200 pt-4 space-y-2">
            <button
              phx-click="checkin"
              phx-disable-with="Registrando..."
              class="btn btn-primary w-full gap-2"
            >
              <.icon name="hero-check-circle" class="size-5" /> Confirmar Check-in de Hoje
            </button> <.link navigate={~p"/habits"} class="btn btn-ghost w-full">Cancelar</.link>
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
